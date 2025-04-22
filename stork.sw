contract;

mod stork_structs;
mod stork_storage;
mod stork_errors;
mod stork_events;
mod stork_getters;
mod stork_setters;
mod stork_verify;

use std::{
    auth::msg_sender,
    bytes::Bytes,
    constants::ZERO_B256,
    contract_id::ContractId,
    hash::Hash,
    storage::StorageMap,
    u256::U256,
    block::timestamp,
};

use stork_structs::{TemporalNumericValue, TemporalNumericValueInput, PublisherSignature};
use stork_storage::State;
use stork_errors::{InsufficientFee, NoFreshUpdate, NotFound, StaleValue, InvalidSignature};
use stork_getters::{latest_canonical_temporal_numeric_value, single_update_fee_in_wei, valid_time_period_seconds, stork_public_key};
use stork_setters::{update_latest_value_if_necessary, set_stork_public_key, set_single_update_fee_in_wei, set_valid_time_period_seconds};
use stork_verify::{verify_stork_signature_v1, verify_publisher_signature_v1, verify_merkle_root, get_publisher_message_hash};

storage {
    state: State = State {
        stork_public_key: Address::from(0),
        single_update_fee_in_wei: 0,
        valid_time_period_seconds: 0,
        latest_canonical_temporal_numeric_values: StorageMap {},
    },
}

abi Stork {
    #[storage(read, write)]
    fn initialize(stork_public_key: Address, valid_time_period_seconds: u64, single_update_fee_in_wei: u64);
    
    #[storage(read, write), payable]
    fn update_temporal_numeric_values_v1(update_data: Vec<TemporalNumericValueInput>);
    
    #[storage(read)]
    fn get_update_fee_v1(update_data: Vec<TemporalNumericValueInput>) -> u64;
    
    #[storage(read)]
    fn get_temporal_numeric_value_v1(id: b256) -> TemporalNumericValue;
    
    #[storage(read)]
    fn get_temporal_numeric_value_unsafe_v1(id: b256) -> TemporalNumericValue;
    
    fn verify_publisher_signatures_v1(signatures: Vec<PublisherSignature>, merkle_root: b256) -> bool;
    
    fn version() -> str[6];
    
    #[storage(read, write)]
    fn update_valid_time_period_seconds(valid_time_period_seconds: u64);
    
    #[storage(read, write)]
    fn update_single_update_fee_in_wei(single_update_fee_in_wei: u64);
    
    #[storage(read, write)]
    fn update_stork_public_key(stork_public_key: Address);
}

impl Stork for Contract {
    #[storage(read, write)]
    fn initialize(stork_public_key: Address, valid_time_period_seconds: u64, single_update_fee_in_wei: u64) {
        set_valid_time_period_seconds(storage.state, valid_time_period_seconds);
        set_single_update_fee_in_wei(storage.state, single_update_fee_in_wei);
        set_stork_public_key(storage.state, stork_public_key);
    }
    
    #[storage(read, write), payable]
    fn update_temporal_numeric_values_v1(update_data: Vec<TemporalNumericValueInput>) {
        let mut num_updates: u16 = 0;
        
        for i in 0..update_data.len() {
            let verified = verify_stork_signature_v1(
                stork_public_key(storage.state),
                update_data[i].id,
                update_data[i].temporal_numeric_value.timestamp_ns,
                update_data[i].temporal_numeric_value.quantized_value,
                update_data[i].publisher_merkle_root,
                update_data[i].value_compute_alg_hash,
                update_data[i].r,
                update_data[i].s,
                update_data[i].v
            );
            
            require(verified, InvalidSignature);
            
            let updated = update_latest_value_if_necessary(storage.state, update_data[i]);
            
            if updated {
                num_updates += 1;
            }
        }
        
        require(num_updates > 0, NoFreshUpdate);
        
        let required_fee = get_total_fee(num_updates);
        require(msg_amount() >= required_fee, InsufficientFee);
    }
    
    #[storage(read)]
    fn get_update_fee_v1(update_data: Vec<TemporalNumericValueInput>) -> u64 {
        get_total_fee(update_data.len() as u64)
    }
    
    #[storage(read)]
    fn get_temporal_numeric_value_v1(id: b256) -> TemporalNumericValue {
        let numeric_value = latest_canonical_temporal_numeric_value(storage.state, id);
        
        require(numeric_value.timestamp_ns != 0, NotFound);
        
        // In Sway, we need to convert nanoseconds to seconds for comparison
        require(timestamp() - (numeric_value.timestamp_ns / 1_000_000_000) <= valid_time_period_seconds(storage.state), StaleValue);
        
        numeric_value
    }
    
    #[storage(read)]
    fn get_temporal_numeric_value_unsafe_v1(id: b256) -> TemporalNumericValue {
        let numeric_value = latest_canonical_temporal_numeric_value(storage.state, id);
        
        require(numeric_value.timestamp_ns != 0, NotFound);
        
        numeric_value
    }
    
    fn verify_publisher_signatures_v1(signatures: Vec<PublisherSignature>, merkle_root: b256) -> bool {
        let mut hashes = Vec::<b256>::new();
        
        for i in 0..signatures.len() {
            if !verify_publisher_signature_v1(
                signatures[i].pub_key,
                signatures[i].asset_pair_id,
                signatures[i].timestamp,
                signatures[i].quantized_value,
                signatures[i].r,
                signatures[i].s,
                signatures[i].v
            ) {
                return false;
            }
            
            let computed = get_publisher_message_hash(
                signatures[i].pub_key,
                signatures[i].asset_pair_id,
                signatures[i].timestamp,
                signatures[i].quantized_value
            );
            
            hashes.push(computed);
        }
        
        verify_merkle_root(hashes, merkle_root)
    }
    
    fn version() -> str[6] {
        "1.0.2"
    }
    
    #[storage(read, write)]
    fn update_valid_time_period_seconds(valid_time_period_seconds: u64) {
        set_valid_time_period_seconds(storage.state, valid_time_period_seconds);
    }
    
    #[storage(read, write)]
    fn update_single_update_fee_in_wei(single_update_fee_in_wei: u64) {
        set_single_update_fee_in_wei(storage.state, single_update_fee_in_wei);
    }
    
    #[storage(read, write)]
    fn update_stork_public_key(stork_public_key: Address) {
        set_stork_public_key(storage.state, stork_public_key);
    }
}

fn get_total_fee(total_num_updates: u64) -> u64 {
    total_num_updates * single_update_fee_in_wei(storage.state)
}
