import chip8/cpu/address_register
import gleam/float
import gleam/int
import gleam/result
import qcheck

pub fn address_register_test() {
  use value <- qcheck.given(valid_value_generator())
  let assert Ok(address_register) = address_register.new(value)

  assert address_register |> is_equal(value)

  use other_value <- qcheck.given(valid_value_generator())

  let assert Ok(new_address_register) =
    address_register |> address_register.set_value(other_value)

  assert new_address_register |> is_equal(other_value)
}

pub fn address_register_overflow_test() {
  use valid_value <- qcheck.given(valid_value_generator())
  use overflow_value <- qcheck.given(int_ge(65_536))
  let assert Error(address_register.ValueOverflow(overflow_value)) =
    address_register.new(overflow_value)
  let assert Error(address_register.ValueOverflow(65_536)) =
    address_register.new(65_536)

  let assert Ok(valid_address_register) = address_register.new(valid_value)

  let assert Error(address_register.ValueOverflow(overflow_value)) =
    valid_address_register |> address_register.set_value(overflow_value)

  Nil
}

pub fn address_register_underflow_test() {
  use valid_value <- qcheck.given(valid_value_generator())
  use underflow_value <- qcheck.given(int_lt(0))
  let assert Error(address_register.ValueUnderflow(underflow_value)) =
    address_register.new(underflow_value)

  let assert Ok(valid_address_register) = address_register.new(valid_value)

  let assert Error(address_register.ValueUnderflow(underflow_value)) =
    valid_address_register |> address_register.set_value(underflow_value)

  Nil
}

fn is_equal(
  address_register: address_register.AddressRegister,
  value: Int,
) -> Bool {
  address_register |> address_register.get_value == value
}

fn int_ge(x: Int) -> qcheck.Generator(Int) {
  use rand <- qcheck.map(qcheck.small_non_negative_int())
  rand + x
}

fn int_lt(x: Int) -> qcheck.Generator(Int) {
  use rand <- qcheck.map(qcheck.small_strictly_positive_int())
  x - rand
}

fn valid_value_generator() -> qcheck.Generator(Int) {
  qcheck.bounded_int(
    0,
    fn() {
      let assert Ok(max_valid_value) =
        int.power(2, 16.0)
        |> result.map(fn(num) { num |> float.subtract(1.0) |> float.truncate })
      max_valid_value
    }(),
  )
}
