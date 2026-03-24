import chip8/cpu/fixed_length_bit_array
import gleam/result

/// A 4096-byte long memory array, storing 8-bit values.
pub opaque type Memory {
  Memory(fixed_length_bit_array.FixedLengthBitArray)
}

pub type MemoryError {
  FailedToInitialise
  TriedToAccessFakeAddress(address: Int)
  ValueOverflow(value: Int)
  ValueUnderflow(value: Int)
}

pub fn new() -> Result(Memory, MemoryError) {
  fixed_length_bit_array.new(length: 4096, bytes: 1)
  |> result.replace_error(FailedToInitialise)
  |> result.map(Memory)
}

pub fn get_value_at(
  memory: Memory,
  address address: Int,
) -> Result(Int, MemoryError) {
  let Memory(array) = memory

  array
  |> fixed_length_bit_array.get_value_at_address(address)
  |> result.map_error(from_fl_ba_error)
}

pub fn set_value_at(
  memory: Memory,
  address address: Int,
  to value: Int,
) -> Result(Memory, MemoryError) {
  let Memory(array) = memory

  array
  |> fixed_length_bit_array.set_value_at_address(address, value)
  |> result.map(Memory)
  |> result.map_error(from_fl_ba_error)
}

fn from_fl_ba_error(
  error: fixed_length_bit_array.FixedLengthBitArrayError,
) -> MemoryError {
  case error {
    fixed_length_bit_array.BadAddress(address:) ->
      TriedToAccessFakeAddress(address:)
    fixed_length_bit_array.ValueOverflow(value:) -> ValueOverflow(value:)
    fixed_length_bit_array.ValueUnderflow(value:) -> ValueUnderflow(value:)
    fixed_length_bit_array.NonPositiveByteLength(byte_length:) -> panic
  }
}
