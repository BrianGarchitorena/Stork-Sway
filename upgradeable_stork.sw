contract;

mod stork_structs;
mod stork_storage;
mod stork_errors;
mod stork_events;
mod stork_getters;
mod stork_setters;
mod stork_verify;
mod stork;

use std::{
    auth::{msg_sender, AuthError},
    bytes::Bytes,
    constants::ZERO_B256,
    contract_id::ContractId,
    hash::Hash,
    storage::StorageMap,
    u256::U256,
};

use stork::Stork;

storage {
    owner: Address = Address::from(0),
    initialized: bool = false,
}

abi UpgradeableStork {
    #[storage(read, write)]
    fn initialize(initial_owner: Address, stork_public_key: Address, valid_time_period_seconds: u64, single_update_fee_in_wei: u64);
    
    #[storage(read, write)]
    fn update_valid_time_period_seconds(valid_time_period_seconds: u64);
    
    #[storage(read, write)]
    fn update_single_update_fee_in_wei(single_update_fee_in_wei: u64);
    
    #[storage(read, write)]
    fn update_stork_public_key(stork_public_key: Address);
    
    #[storage(read)]
    fn owner() -> Address;
    
    #[storage(read, write)]
    fn transfer_ownership(new_owner: Address);
}

impl UpgradeableStork for Contract {
    #[storage(read, write)]
    fn initialize(initial_owner: Address, stork_public_key: Address, valid_time_period_seconds: u64, single_update_fee_in_wei: u64) {
        require(!storage.initialized, "Already initialized");
        
        storage.owner = initial_owner;
        storage.initialized = true;
        
        // Initialize the Stork contract
        abi(Stork, self.id()).initialize(stork_public_key, valid_time_period_seconds, single_update_fee_in_wei);
    }
    
    #[storage(read, write)]
    fn update_valid_time_period_seconds(valid_time_period_seconds: u64) {
        require(msg_sender().unwrap() == storage.owner, AuthError);
        
        abi(Stork, self.id()).update_valid_time_period_seconds(valid_time_period_seconds);
    }
    
    #[storage(read, write)]
    fn update_single_update_fee_in_wei(single_update_fee_in_wei: u64) {
        require(msg_sender().unwrap() == storage.owner, AuthError);
        
        abi(Stork, self.id()).update_single_update_fee_in_wei(single_update_fee_in_wei);
    }
    
    #[storage(read, write)]
    fn update_stork_public_key(stork_public_key: Address) {
        require(msg_sender().unwrap() == storage.owner, AuthError);
        
        abi(Stork, self.id()).update_stork_public_key(stork_public_key);
    }
    
    #[storage(read)]
    fn owner() -> Address {
        storage.owner
    }
    
    #[storage(read, write)]
    fn transfer_ownership(new_owner: Address) {
        require(msg_sender().unwrap() == storage.owner, AuthError);
        require(new_owner != Address::from(0), "New owner is zero address");
        
        storage.owner = new_owner;
    }
}
