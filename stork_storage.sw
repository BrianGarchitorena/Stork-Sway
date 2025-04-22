library stork_storage;

use std::{
    auth::msg_sender,
    bytes::Bytes,
    constants::ZERO_B256,
    contract_id::ContractId,
    hash::Hash,
    storage::StorageMap,
    u256::U256,
};

use ::stork_structs::TemporalNumericValue;

pub struct State {
    // For verifying the authenticity of the passed data
    stork_public_key: Address,
    single_update_fee_in_wei: u64,
    // Maximum acceptable time period before value is considered to be stale.
    // This includes attestation delay, block time, and potential clock drift
    // between the source/target chains.
    valid_time_period_seconds: u64,
    // Mapping of cached numeric temporal data
    latest_canonical_temporal_numeric_values: StorageMap<b256, TemporalNumericValue>,
}
