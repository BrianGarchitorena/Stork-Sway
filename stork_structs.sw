library stork_structs;

use std::{
    auth::msg_sender,
    bytes::Bytes,
    constants::ZERO_B256,
    contract_id::ContractId,
    hash::Hash,
    storage::StorageMap,
    u256::U256,
};

pub struct TemporalNumericValue {
    // nanosecond level precision timestamp of latest publisher update in batch
    timestamp_ns: u64,
    // should be able to hold all necessary numbers
    quantized_value: i192,
}

pub struct TemporalNumericValueInput {
    temporal_numeric_value: TemporalNumericValue,
    id: b256,
    publisher_merkle_root: b256,
    value_compute_alg_hash: b256,
    r: b256,
    s: b256,
    v: u8,
}

pub struct PublisherSignature {
    pub_key: Address,
    asset_pair_id: str[32],
    timestamp: u64,
    quantized_value: u256,
    r: b256,
    s: b256,
    v: u8,
}
