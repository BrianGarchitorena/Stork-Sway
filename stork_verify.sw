library stork_verify;

use std::{
    auth::msg_sender,
    bytes::Bytes,
    constants::ZERO_B256,
    contract_id::ContractId,
    hash::Hash,
    storage::StorageMap,
    u256::U256,
    ecr::ec_recover_address,
};

use ::stork_structs::PublisherSignature;

fn get_eth_signed_message_hash32(message: b256) -> b256 {
    // Equivalent to keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message))
    let prefix = "\x19Ethereum Signed Message:\n32";
    let mut data = Bytes::new();
    data.append(prefix);
    data.append(message);
    
    data.keccak256()
}

fn get_stork_message_hash_v1(
    stork_pub_key: Address,
    id: b256,
    recv_time: u64,
    quantized_value: i192,
    publisher_merkle_root: b256,
    value_compute_alg_hash: b256
) -> b256 {
    // Equivalent to keccak256(abi.encodePacked(storkPubKey, id, recvTime, quantizedValue, publisherMerkleRoot, valueComputeAlgHash))
    let mut data = Bytes::new();
    data.append(stork_pub_key);
    data.append(id);
    data.append(recv_time);
    data.append(quantized_value);
    data.append(publisher_merkle_root);
    data.append(value_compute_alg_hash);
    
    data.keccak256()
}

pub fn get_publisher_message_hash(
    oracle_name: Address,
    asset_pair_id: str[32],
    timestamp: u64,
    value: u256
) -> b256 {
    // Equivalent to keccak256(abi.encodePacked(oracleName, assetPairId, timestamp, value))
    let mut data = Bytes::new();
    data.append(oracle_name);
    data.append(asset_pair_id);
    data.append(timestamp);
    data.append(value);
    
    data.keccak256()
}

fn get_signer(
    signed_message_hash: b256,
    r: b256,
    s: b256,
    v: u8
) -> Address {
    // Using Fuel's ec_recover_address instead of Solidity's ecrecover
    ec_recover_address(signed_message_hash, r, s, v)
}

fn compute_merkle_root(leaves: Vec<b256>) -> b256 {
    require(leaves.len() > 0, "No leaves provided");
    
    let mut current_leaves = leaves;
    
    while current_leaves.len() > 1 {
        let mut next_level = Vec::new();
        
        if current_leaves.len() % 2 != 0 {
            // If odd number of leaves, duplicate the last one
            current_leaves.push(current_leaves[current_leaves.len() - 1]);
        }
        
        let mut i = 0;
        while i < current_leaves.len() {
            let mut pair_data = Bytes::new();
            pair_data.append(current_leaves[i]);
            pair_data.append(current_leaves[i + 1]);
            
            next_level.push(pair_data.keccak256());
            i += 2;
        }
        
        current_leaves = next_level;
    }
    
    current_leaves[0]
}

pub fn verify_merkle_root(leaves: Vec<b256>, root: b256) -> bool {
    compute_merkle_root(leaves) == root
}

pub fn verify_publisher_signature_v1(
    oracle_pub_key: Address,
    asset_pair_id: str[32],
    timestamp: u64,
    value: u256,
    r: b256,
    s: b256,
    v: u8
) -> bool {
    let msg_hash = get_publisher_message_hash(
        oracle_pub_key,
        asset_pair_id,
        timestamp,
        value
    );
    
    let signed_message_hash = get_eth_signed_message_hash32(msg_hash);
    
    // Verify hash was generated by the actual user
    let signer = get_signer(signed_message_hash, r, s, v);
    
    signer == oracle_pub_key
}

pub fn verify_stork_signature_v1(
    stork_pub_key: Address,
    id: b256,
    recv_time: u64,
    quantized_value: i192,
    publisher_merkle_root: b256,
    value_compute_alg_hash: b256,
    r: b256,
    s: b256,
    v: u8
) -> bool {
    let msg_hash = get_stork_message_hash_v1(
        stork_pub_key,
        id,
        recv_time,
        quantized_value,
        publisher_merkle_root,
        value_compute_alg_hash
    );
    
    let signed_message_hash = get_eth_signed_message_hash32(msg_hash);
    
    // Verify hash was generated by the actual user
    let signer = get_signer(signed_message_hash, r, s, v);
    
    signer == stork_pub_key
}
