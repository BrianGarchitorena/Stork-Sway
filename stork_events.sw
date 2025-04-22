library stork_events;

use ::stork_structs::TemporalNumericValue;

// Emitted when the latest value with `id` has received a fresh update.
pub struct ValueUpdate {
    id: b256,
    timestamp_ns: u64,
    quantized_value: i192,
}
