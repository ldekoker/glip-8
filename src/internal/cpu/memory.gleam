import gleam/result
import utils

pub opaque type Memory {
  Memory(memory: BitArray)
}

pub fn new() -> Memory {
  Memory(memory: utils.construct_bit_array_of_zeros(length: 4096, bits: 8))
}

pub fn set_address(
  memory: Memory,
  address: Int,
  value: Int,
) -> Result(Memory, Nil) {
  let Memory(bytes) = memory
  use new_bytes <- result.try(
    bytes |> utils.replace_bit_array_value_at(address, with: value),
  )

  Ok(Memory(new_bytes))
}

pub fn get_address(memory: Memory, address: Int) -> Result(Int, Nil) {
  let Memory(bytes) = memory
  bytes |> utils.get_bit_array_value_at(address)
}
