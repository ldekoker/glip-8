import chip8/cpu/address_register
import gleam/result

pub fn address_register_test() {
  use address_register <- result.try(address_register.new(0))

  assert address_register |> is_equal(0)

  use new_address_register <- result.try(
    address_register |> address_register.set_value(9),
  )

  assert new_address_register |> is_equal(9)
  Ok(Nil)
}

pub fn address_register_overflow_test() {
  let assert Error(address_register.ValueOverflow(65_536)) =
    address_register.new(65_536)

  use valid_address_register <- result.try(address_register.new(0))

  let assert Error(address_register.ValueOverflow(65_536)) =
    valid_address_register |> address_register.set_value(65_536)
}

pub fn address_register_underflow_test() {
  let assert Error(address_register.ValueUnderflow(-1)) =
    address_register.new(-1)

  use valid_address_register <- result.try(address_register.new(0))

  let assert Error(address_register.ValueUnderflow(-1)) =
    valid_address_register |> address_register.set_value(-1)
}

fn is_equal(
  address_register: address_register.AddressRegister,
  value: Int,
) -> Bool {
  address_register |> address_register.get_value == value
}
