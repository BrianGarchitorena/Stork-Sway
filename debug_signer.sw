contract;

use std::{
    crypto::secp256k1::Secp256k1,
    crypto::message::Message,
    logging::log,
};

abi DebugSigner {
    fn test_get_signer(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity;
    fn test_with_v(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity;
}

// Original implementation
fn get_signer(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity {
    Identity::Address(Address::from(Secp256k1::from((r, s)).address(Message::from(signed_message_hash).unwrap())))
}

// Modified implementation with error handling and debugging
fn get_signer_with_debug(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity {
    // Log input parameters for debugging
    log(signed_message_hash);
    log(r);
    log(s);
    log(v);
    
    // Try to create Message from hash
    let message_result = Message::from(signed_message_hash);
    if message_result.is_err() {
        log("Error creating Message from hash");
        return Identity::Address(Address::zero());
    }
    let message = message_result.unwrap();
    
    // Create Secp256k1 from r and s
    let secp = Secp256k1::from((r, s));
    
    // Try to get address
    let address_result = secp.address(message);
    if address_result.is_err() {
        log("Error getting address from Secp256k1");
        return Identity::Address(Address::zero());
    }
    
    // Return the identity
    Identity::Address(Address::from(address_result.unwrap()))
}

// Alternative implementation that tries to use v parameter
fn get_signer_with_v(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity {
    // Create Message from hash
    let message_result = Message::from(signed_message_hash);
    if message_result.is_err() {
        log("Error creating Message from hash");
        return Identity::Address(Address::zero());
    }
    let message = message_result.unwrap();
    
    // Try to use v parameter in recovery
    // Note: This is experimental and depends on how Sway's Secp256k1 implementation works
    let recovery_id = if v == 27u8 { 0u8 } else if v == 28u8 { 1u8 } else { v };
    
    // Try different approaches based on Sway's API
    // Approach 1: Try to use v directly if the API supports it
    let secp = match recovery_id {
        0u8 | 1u8 => Secp256k1::from_recovery_id((r, s), recovery_id),
        _ => Secp256k1::from((r, s)) // Fallback to original method
    };
    
    // Get address
    let address_result = secp.address(message);
    if address_result.is_err() {
        log("Error getting address with recovery_id");
        return Identity::Address(Address::zero());
    }
    
    Identity::Address(Address::from(address_result.unwrap()))
}

impl DebugSigner for Contract {
    fn test_get_signer(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity {
        get_signer_with_debug(signed_message_hash, r, s, v)
    }
    
    fn test_with_v(signed_message_hash: b256, r: b256, s: b256, v: u8) -> Identity {
        get_signer_with_v(signed_message_hash, r, s, v)
    }
}
