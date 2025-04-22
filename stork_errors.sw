library stork_errors;

// Insufficient fee is paid to the method.
pub enum InsufficientFee {}

// There is no fresh update, whereas expected fresh updates.
pub enum NoFreshUpdate {}

// Not found.
pub enum NotFound {}

// Requested value is stale.
pub enum StaleValue {}

// Signature is invalid.
pub enum InvalidSignature {}
