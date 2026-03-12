import gleam/result
import utils

pub opaque type ByteMemory {
  ByteMemory(memory: BitArray)
}

pub opaque type ByteMemoryError {
  BadAddress(address: Int)
}

pub fn new(length: Int) -> ByteMemory {
  ByteMemory(memory: utils.construct_bit_array_of_zeros(length: length, bits: 8))
}

pub fn get_value_at_address(
  memory: ByteMemory,
  address: Int,
) -> Result(Int, ByteMemoryError) {
  let ByteMemory(bytes) = memory
  bytes
  |> utils.get_bit_array_value_at(address)
  |> result.replace_error(BadAddress(address:))
}

pub fn set_value_at_address(
  memory: ByteMemory,
  address: Int,
  value: Int,
) -> Result(ByteMemory, ByteMemoryError) {
  let ByteMemory(bytes) = memory
  use new_bytes <- result.try(
    bytes
    |> utils.replace_bit_array_value_at(address, with: value)
    |> result.replace_error(BadAddress(address:)),
  )

  Ok(ByteMemory(new_bytes))
}
