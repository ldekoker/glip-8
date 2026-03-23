import chip8/cpu/fixed_length_bit_array
import gleam/result

/// A 4096-byte long memory array, storing 8-bit values.
pub opaque type Memory {
  Memory(fixed_length_bit_array.FixedLengthBitArray)
}

pub type MemoryError {
  FailedToInitialise
  FailedToFetch(address: Int)
  FailedToSet(address: Int)
}

pub fn new() -> Result(Memory, MemoryError) {
  fixed_length_bit_array.new(length: 4096, bits: 8)
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
  |> result.replace_error(FailedToFetch(address:))
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
  |> result.replace_error(FailedToSet(address:))
}
