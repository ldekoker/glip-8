import chip8/cpu/fixed_length_bit_array
import gleam/int
import gleam/result

pub fn data_registers_initialise_test() {
  let assert Ok(data_registers) = fixed_length_bit_array.new(16, 1)

  assert int.range(from: 0, to: 15, with: True, run: fn(so_far, address) {
    so_far
    && data_registers |> fixed_length_bit_array.get_value_at_address(address)
    == Ok(0)
  })
}

pub fn data_registers_set_test() {
  let assert Ok(data_registers) =
    fixed_length_bit_array.new(16, 1) |> result.try(set_data_registers)

  assert int.range(from: 0, to: 15, with: True, run: fn(so_far, address) {
    so_far
    && data_registers |> fixed_length_bit_array.get_value_at_address(address)
    == Ok(address)
  })
}

fn set_data_registers(
  data_registers: fixed_length_bit_array.FixedLengthBitArray,
) {
  data_registers
  |> fixed_length_bit_array.set_value_at_address(1, 1)
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 2, 2))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 3, 3))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 4, 4))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 5, 5))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 6, 6))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 7, 7))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 8, 8))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 9, 9))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 10, 10))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 11, 11))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 12, 12))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 13, 13))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 14, 14))
  |> result.try(fixed_length_bit_array.set_value_at_address(_, 15, 15))
}

pub fn address_access_error_test() {
  // Create a ByteArray with 10 elements
  let assert Ok(memory) = fixed_length_bit_array.new(10, 1)
  let address = 11

  // Access the 11th element
  let bad_access = fixed_length_bit_array.get_value_at_address(memory, address)

  assert result.is_error(bad_access)
  let assert Error(fixed_length_bit_array.BadAddress(bad_address)) = bad_access
  assert bad_address == address
}

pub fn address_set_error_test() {
  // Create a ByteArray with 10 elements
  let assert Ok(memory) = fixed_length_bit_array.new(10, 1)
  let address = 11
  let new_value = 1

  // Set the 11th element
  let bad_access =
    fixed_length_bit_array.set_value_at_address(memory, address, new_value)

  assert result.is_error(bad_access)
  let assert Error(fixed_length_bit_array.BadAddress(bad_address)) = bad_access
  assert bad_address == address
}

pub fn value_set_overflow_test() {
  // Create a ByteArray with 10 elements
  let assert Ok(memory) = fixed_length_bit_array.new(10, 1)
  let address = 10
  let new_value = 257

  // Set the 10th element
  let bad_access =
    fixed_length_bit_array.set_value_at_address(memory, address, new_value)

  let assert Error(fixed_length_bit_array.ValueOverflow(overflow_value)) =
    bad_access
  assert overflow_value == 257
}

pub fn value_set_underflow_test() {
  // Create a ByteArray with 10 elements
  let assert Ok(memory) = fixed_length_bit_array.new(10, 1)
  let address = 10
  let new_value = -1

  // Set the 10th element
  let assert Error(fixed_length_bit_array.ValueUnderflow(-1)) =
    fixed_length_bit_array.set_value_at_address(memory, address, new_value)
}
