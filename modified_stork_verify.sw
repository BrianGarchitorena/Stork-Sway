// Modified StorkVerify with improved error handling and debugging
contract;

use sway_libs::signed_integers::i256::*;
use std::bytes::Bytes;
use std::crypto::secp256k1::Secp256k1;
use std::crypto::message::Message;
use std::crypto::signature::Signature;
use std::constants::ZERO_B256;
use std::logging::log;

abi StorkVerify {
    fn verify_merkle_root(leaves: Vec<b256>, root: b256) -> bool;
    fn verify_publisher_signature_v_1(oracle_pub_key: Identity, asset_pair_id: str, timestamp: u256, value: u256, r: b256, s: b256, v: u8) -> bool;
    fn verify_stork_signature_v_1(stork_pub_key: Identity, id: b256, recv_time: u256, quantized_value: I256, publisher_merkle_root: b256, value_compute_alg_hash: b256, r: b256, s: b256, v: u8) -> bool;
    
    // Debug functions
    fn debug_get_signer(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity;
    fn debug_get_publisher_message_hash(oracle_name: Identity, asset_pair_id: str, timestamp: u256, value: u256) -> b256;
    fn debug_get_eth_signed_message_hash(message: b256) -> b256;
}

fn get_eth_signed_message_hash_32(message: b256) -> b256 {
    let result = std::hash::keccak256({
        let mut bytes = Bytes::new();
        bytes.append(Bytes::from(core::codec::encode("\x19Ethereum Signed Message:\n32")));
        bytes.append(Bytes::from(core::codec::encode(message)));
        bytes
    });
    log("Eth signed message hash:");
    log(result);
    result
}

fn get_stork_message_hash_v_1(stork_pub_key: Identity, id: b256, recv_time: u256, quantized_value: I256, publisher_merkle_root: b256, value_compute_alg_hash: b256) -> b256 {
    std::hash::keccak256({
        let mut bytes = Bytes::new();
        bytes.append(Bytes::from(core::codec::encode(stork_pub_key)));
        bytes.append(Bytes::from(core::codec::encode(id)));
        bytes.append(Bytes::from(core::codec::encode(recv_time)));
        bytes.append(Bytes::from(core::codec::encode(quantized_value)));
        bytes.append(Bytes::from(core::codec::encode(publisher_merkle_root)));
        bytes.append(Bytes::from(core::codec::encode(value_compute_alg_hash)));
        bytes
    })
}

fn get_publisher_message_hash(oracle_name: Identity, asset_pair_id: str, timestamp: u256, value: u256) -> b256 {
    let result = std::hash::keccak256({
        let mut bytes = Bytes::new();
        bytes.append(Bytes::from(core::codec::encode(oracle_name)));
        bytes.append(Bytes::from(core::codec::encode(asset_pair_id)));
        bytes.append(Bytes::from(core::codec::encode(timestamp)));
        bytes.append(Bytes::from(core::codec::encode(value)));
        bytes
    });
    log("Publisher message hash:");
    log(result);
    return result;
}

// Correct implementation based on Sway documentation
fn get_signer(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity {
    log("Using correct Sway implementation");
    log("Signed message hash:");
    log(signed_message_hash);
    log("r:");
    log(r);
    log("s:");
    log(s);
    log("v:");
    log(v);
    
    // Try-catch pattern for better error handling
    let message_result = Message::from(signed_message_hash);
    if message_result.is_err() {
        log("Error: Failed to create Message from signed_message_hash");
        return Identity::Address(Address::zero());
    }
    
    let message = message_result.unwrap();
    
    // Create a Signature with Secp256k1 signature
    let secp256k1_sig = Signature::Secp256k1(Secp256k1::from((r, s)));
    
    // Get address from signature
    let address_result = secp256k1_sig.address(message);
    if address_result.is_err() {
        log("Error: Failed to get address from Signature");
        return Identity::Address(Address::zero());
    }
    
    let address = address_result.unwrap();
    log("Recovered address:");
    log(address);
    
    Identity::Address(address)
}

// Alternative implementation that tries to use v parameter
fn get_signer_with_v(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity {
    log("Using get_signer_with_v implementation");
    log("v value:");
    log(v);
    
    // Convert Ethereum v value (27/28) to recovery_id (0/1) if needed
    let recovery_id = if v == 27u8 { 0u8 } else if v == 28u8 { 1u8 } else { v };
    log("Recovery ID:");
    log(recovery_id);
    
    let message_result = Message::from(signed_message_hash);
    if message_result.is_err() {
        log("Error creating Message from hash");
        return Identity::Address(Address::zero());
    }
    let message = message_result.unwrap();
    
    // Create a Signature with Secp256k1 signature
    // In Sway, the v parameter might be handled internally
    let secp256k1_sig = Signature::Secp256k1(Secp256k1::from((r, s)));
    
    let address_result = secp256k1_sig.address(message);
    if address_result.is_err() {
        log("Error getting address from Signature");
        return Identity::Address(Address::zero());
    }
    
    Identity::Address(address_result.unwrap())
}

fn compute_merkle_root(leaves: Vec<b256>) -> b256 {
    let mut leaves: Vec<b256> = leaves;
    require(leaves.len() > 0, "No leaves provided");
    while leaves.len() > 1 {
        if leaves.len() % 2 != 0 {
            let mut extended_leaves = {
                let mut v: Vec<b256> = Vec::with_capacity(leaves.len() + 1);
                let mut i = 0;
                while i < leaves.len() + 1 {
                    v.push(ZERO_B256);
                    i += 1;
                }
                v
            };
            let mut i: u64 = 0;
            while i < leaves.len() {
                extended_leaves.set(i, leaves.get(i).unwrap());
                i += 1;
            }
            extended_leaves.set(leaves.len(), leaves.get(leaves.len() - 1).unwrap());
            leaves = leaves;
        }
        let mut next_level = {
            let mut v: Vec<b256> = Vec::with_capacity(leaves.len() / 2);
            let mut i = 0;
            while i < leaves.len() / 2 {
                v.push(ZERO_B256);
                i += 1;
            }
            v
        };
        let mut i: u64 = 0;
        while i < leaves.len() {
            next_level.set(i / 2, std::hash::keccak256({
                let mut bytes = Bytes::new();
                bytes.append(Bytes::from(core::codec::encode(leaves.get(i).unwrap())));
                bytes.append(Bytes::from(core::codec::encode(leaves.get(i + 1).unwrap())));
                bytes
            }));
            i += 2;
        }
        leaves = leaves;
    }
    leaves.get(0).unwrap()
}

impl StorkVerify for Contract {
    fn verify_merkle_root(leaves: Vec<b256>, root: b256) -> bool {
        compute_merkle_root(leaves) == root
    }

    fn verify_publisher_signature_v_1(oracle_pub_key: Identity, asset_pair_id: str, timestamp: u256, value: u256, r: b256, s: b256, v: u8) -> bool {
        log("verify_publisher_signature_v_1 called");
        log("Oracle pub key:");
        log(oracle_pub_key);
        
        let msg_hash = get_publisher_message_hash(oracle_pub_key, asset_pair_id, timestamp, value);
        let signed_message_hash = get_eth_signed_message_hash_32(msg_hash);
        
        // Try both implementations
        log("Trying original implementation:");
        let signer = get_signer(signed_message_hash, r, s, v);
        log("Recovered signer:");
        log(signer);
        
        log("Trying implementation with v:");
        let signer_with_v = get_signer_with_v(signed_message_hash, r, s, v);
        log("Recovered signer with v:");
        log(signer_with_v);
        
        // Check both results
        let original_match = signer == oracle_pub_key;
        let v_match = signer_with_v == oracle_pub_key;
        
        log("Original implementation match:");
        log(original_match);
        log("V implementation match:");
        log(v_match);
        
        // Return true if either implementation works
        original_match || v_match
    }

    fn verify_stork_signature_v_1(stork_pub_key: Identity, id: b256, recv_time: u256, quantized_value: I256, publisher_merkle_root: b256, value_compute_alg_hash: b256, r: b256, s: b256, v: u8) -> bool {
        log("verify_stork_signature_v_1 called");
        log("Stork pub key:");
        log(stork_pub_key);
        
        let msg_hash = get_stork_message_hash_v_1(stork_pub_key, id, recv_time, quantized_value, publisher_merkle_root, value_compute_alg_hash);
        let signed_message_hash = get_eth_signed_message_hash_32(msg_hash);
        
        // Try both implementations
        log("Trying original implementation:");
        let signer = get_signer(signed_message_hash, r, s, v);
        log("Recovered signer:");
        log(signer);
        
        log("Trying implementation with v:");
        let signer_with_v = get_signer_with_v(signed_message_hash, r, s, v);
        log("Recovered signer with v:");
        log(signer_with_v);
        
        // Check both results
        let original_match = signer == stork_pub_key;
        let v_match = signer_with_v == stork_pub_key;
        
        log("Original implementation match:");
        log(original_match);
        log("V implementation match:");
        log(v_match);
        
        // Return true if either implementation works
        original_match || v_match
    }
    
    // Debug functions
    fn debug_get_signer(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity {
        get_signer(signed_message_hash, r, s, v)
    }
    
    fn debug_get_publisher_message_hash(oracle_name: Identity, asset_pair_id: str, timestamp: u256, value: u256) -> b256 {
        get_publisher_message_hash(oracle_name, asset_pair_id, timestamp, value)
    }
    
    fn debug_get_eth_signed_message_hash(message: b256) -> b256 {
        get_eth_signed_message_hash_32(message)
    }
}
