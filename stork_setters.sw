library stork_setters;

use std::{
    auth::msg_sender,
    bytes::Bytes,
    constants::ZERO_B256,
    contract_id::ContractId,
    hash::Hash,
    storage::StorageMap,
    u256::U256,
};

use ::stork_structs::{TemporalNumericValue, TemporalNumericValueInput};
use ::stork_storage::State;
use ::stork_events::ValueUpdate;

pub fn update_latest_value_if_necessary(
    state: State, 
    input: TemporalNumericValueInput
) -> bool {
    let latest_receive_time = state.latest_canonical_temporal_numeric_values.get(input.id).timestamp_ns;
    
    if input.temporal_numeric_value.timestamp_ns > latest_receive_time {
        state.latest_canonical_temporal_numeric_values.insert(
            input.id, 
            input.temporal_numeric_value
        );
        
        // Emit event
        log(ValueUpdate {
            id: input.id,
            timestamp_ns: input.temporal_numeric_value.timestamp_ns,
            quantized_value: input.temporal_numeric_value.quantized_value,
        });
        
        return true;
    }
    
    false
}

pub fn set_stork_public_key(state: State, stork_public_key: Address) {
    state.stork_public_key = stork_public_key;
}

pub fn set_single_update_fee_in_wei(state: State, fee: u64) {
    state.single_update_fee_in_wei = fee;
}

pub fn set_valid_time_period_seconds(state: State, valid_time_period_seconds: u64) {
    state.valid_time_period_seconds = valid_time_period_seconds;
}
