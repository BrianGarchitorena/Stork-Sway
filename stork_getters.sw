library stork_getters;

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
use ::stork_storage::State;

pub fn latest_canonical_temporal_numeric_value(state: State, id: b256) -> TemporalNumericValue {
    state.latest_canonical_temporal_numeric_values.get(id)
}

pub fn single_update_fee_in_wei(state: State) -> u64 {
    state.single_update_fee_in_wei
}

pub fn valid_time_period_seconds(state: State) -> u64 {
    state.valid_time_period_seconds
}

pub fn stork_public_key(state: State) -> Address {
    state.stork_public_key
}
