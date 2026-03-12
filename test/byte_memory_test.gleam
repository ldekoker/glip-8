import gleam/int
import gleam/result
import internal/cpu/byte_memory

pub fn data_registers_initialise_test() {
  let data_registers = byte_memory.new(16)

  assert int.range(from: 0, to: 15, with: True, run: fn(so_far, idx) {
    so_far && byte_memory.get_value_at_address(data_registers, idx) == Ok(0)
  })
}

pub fn data_registers_set_test() {
  use data_registers <- result.try(set_data_registers(byte_memory.new(16)))

  assert int.range(from: 0, to: 15, with: True, run: fn(so_far, idx) {
    so_far && byte_memory.get_value_at_address(data_registers, idx) == Ok(idx)
  })

  Ok(Nil)
}

fn set_data_registers(d: byte_memory.ByteMemory) {
  d
  |> byte_memory.set_value_at_address(1, 1)
  |> result.try(byte_memory.set_value_at_address(_, 2, 2))
  |> result.try(byte_memory.set_value_at_address(_, 3, 3))
  |> result.try(byte_memory.set_value_at_address(_, 4, 4))
  |> result.try(byte_memory.set_value_at_address(_, 5, 5))
  |> result.try(byte_memory.set_value_at_address(_, 6, 6))
  |> result.try(byte_memory.set_value_at_address(_, 7, 7))
  |> result.try(byte_memory.set_value_at_address(_, 8, 8))
  |> result.try(byte_memory.set_value_at_address(_, 9, 9))
  |> result.try(byte_memory.set_value_at_address(_, 10, 10))
  |> result.try(byte_memory.set_value_at_address(_, 11, 11))
  |> result.try(byte_memory.set_value_at_address(_, 12, 12))
  |> result.try(byte_memory.set_value_at_address(_, 13, 13))
  |> result.try(byte_memory.set_value_at_address(_, 14, 14))
  |> result.try(byte_memory.set_value_at_address(_, 15, 15))
}

pub fn address_access_error_test() {
  // Create a ByteArray with 10 elements
  let memory = byte_memory.new(10)
  let address = 11

  // Access the 11th element
  let bad_access = byte_memory.get_value_at_address(memory, address)

  assert result.is_error(bad_access)
  let assert Error(byte_memory.BadAddress(bad_address)) = bad_access
  assert bad_address == address
}

pub fn address_set_error_test() {
  // Create a ByteArray with 10 elements
  let memory = byte_memory.new(10)
  let address = 11
  let new_value = 1

  // Set the 11th element
  let bad_access = byte_memory.set_value_at_address(memory, address, new_value)

  assert result.is_error(bad_access)
  let assert Error(byte_memory.BadAddress(bad_address)) = bad_access
  assert bad_address == address
}

pub fn value_set_overflow_test() {
  // Create a ByteArray with 10 elements
  let memory = byte_memory.new(10)
  let address = 11
  let new_value = 257

  // Set the 11th element
  let bad_access = byte_memory.set_value_at_address(memory, address, new_value)

  assert result.is_error(bad_access)
  let assert Error(byte_memory.ValueOverflow(new_value)) = bad_access
  assert new_value == 257
}
