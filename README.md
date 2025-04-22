# Stork-Sway
Translated Stork Contract from solidity to Sway
# Secp256k1 Signature Recovery Test

This project demonstrates how to implement and test Secp256k1 signature recovery in Sway, based on the one-liner provided by the dev shop:

```sway
Identity::Address(Address::from(Secp256k1::from((r, s)).address(Message::from(signed_message_hash).unwrap())))
```

## Project Structure

- `src/main.sw`: Contains the main contract with two implementations of signature recovery:
  - `recover_address`: The original implementation based on the dev shop's one-liner
  - `recover_address_with_v`: An alternative implementation that tries to use the `v` parameter

## How to Use

Once you have the Fuel toolchain installed, you can build and test this project:

1. Build the project:
   ```
   cd secp256k1_test
   forc build
   ```

2. Deploy the contract to a local Fuel node:
   ```
   forc deploy
   ```

3. Test the signature recovery functions with your test data.

## Understanding the Implementation

The key part of the signature recovery is:

```sway
fn recover_address(message_hash: b256, r: b256, s: b256, v: u8) -> Identity {
    Identity::Address(Address::from(Secp256k1::from((r, s)).address(Message::from(message_hash).unwrap())))
}
```

This function:
1. Creates a `Message` from the message hash
2. Creates a `Secp256k1` object from the `r` and `s` components of the signature
3. Recovers the address from the signature and message
4. Returns the address as an `Identity`

## Debugging

The implementations include extensive logging to help debug any issues:
- Input parameters are logged
- Error handling is added around critical operations
- Results are logged

## Notes on the `v` Parameter

In Ethereum's ECDSA signature recovery, the `v` parameter (recovery ID) is crucial for determining which of the two possible public keys to use. However, in the Sway implementation provided by the dev shop, the `v` parameter is not used.

The `recover_address_with_v` function attempts to use the `v` parameter in different ways, but this depends on how Sway's Secp256k1 implementation works.

## Alternative Approaches

If the standard implementation doesn't work, you can try:
1. Converting the Ethereum `v` value (27/28) to a recovery ID (0/1)
2. Using a different method to create the Secp256k1 object
3. Checking if Sway's Secp256k1 implementation has a method that takes a recovery ID
