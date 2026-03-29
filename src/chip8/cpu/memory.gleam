import gleam/bool
import gleam/dict
import gleam/result

/// # Memory
/// A 4096-byte long memory array, storing 8-bit values.
/// 
/// Two operations:
/// - get_value_at(index)
/// - set_value_at(index, new_value)
/// 
/// Memory indices are in [0, 4095].
pub opaque type Memory {
  Memory(dict.Dict(Int, Int))
}

pub type MemoryError {
  TriedToAccessFakeAddress(address: Int)
  ValueOverflow(value: Int)
  ValueUnderflow(value: Int)
}

pub fn new() -> Memory {
  dict.new() |> Memory
}

/// Fetches value at memory address.
/// If the address is valid but unset, returns 0.
pub fn get_value_at(
  memory: Memory,
  address address: Int,
) -> Result(Int, MemoryError) {
  use <- validate_address(address)
  let Memory(dict) = memory

  dict
  |> dict.get(address)
  |> result.unwrap(0)
  |> Ok
}

/// Sets value at memory address.
/// Validates that the address is 12-bit and the value is 8-bit.
pub fn set_value_at(
  memory: Memory,
  address address: Int,
  to value: Int,
) -> Result(Memory, MemoryError) {
  use <- validate_address(address)
  use <- validate_value(value)
  let Memory(dict) = memory

  dict |> dict.insert(address, value) |> Memory |> Ok
}

// VALIDATION ---------------------------------------------------------

fn validate_address(
  address: Int,
  func: fn() -> Result(a, MemoryError),
) -> Result(a, MemoryError) {
  use <- bool.guard(
    when: address < 0 || address >= 4096,
    return: Error(TriedToAccessFakeAddress(address)),
  )
  func()
}

fn validate_value(
  value: Int,
  func: fn() -> Result(a, MemoryError),
) -> Result(a, MemoryError) {
  use <- bool.guard(when: value >= 256, return: Error(ValueOverflow(value)))
  use <- bool.guard(value < 0, Error(ValueUnderflow(value)))
  func()
}
