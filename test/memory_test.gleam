import chip8/cpu/memory
import qcheck
import test_utils

/// You should be able to set any valid address to any valid value.
pub fn memory_test() {
  let memory = memory.new()
  use address <- qcheck.given(generate_valid_address())
  use value <- qcheck.given(generate_valid_value())

  let assert Ok(new_memory) =
    memory
    |> memory.set_value_at(address, value)

  let assert Ok(set_value) = new_memory |> memory.get_value_at(address)
  assert set_value == value

  Nil
}

/// Given a bad address, it should always return an error.
pub fn memory_bad_access_test() {
  let memory = memory.new()
  use bad_address <- qcheck.given(generate_invalid_address())
  use valid_value <- qcheck.given(generate_valid_value())

  let assert Error(memory.TriedToAccessFakeAddress(bad_address)) =
    memory |> memory.get_value_at(bad_address)

  let assert Error(memory.TriedToAccessFakeAddress(_)) =
    memory |> memory.set_value_at(bad_address, valid_value)

  Nil
}

/// Given a bad value, it should always return an error.
pub fn memory_bad_value_test() -> Nil {
  let memory = memory.new()
  use valid_address <- qcheck.given(generate_valid_address())
  {
    use overflow_value <- qcheck.given(test_utils.int_ge(256))
    let assert Error(memory.ValueOverflow(value)) =
      memory |> memory.set_value_at(valid_address, overflow_value)
    assert value == overflow_value
  }
  {
    qcheck.given(test_utils.int_lt(0), fn(underflow_value) {
      let assert Error(memory.ValueUnderflow(value)) =
        memory |> memory.set_value_at(valid_address, underflow_value)
      assert value == underflow_value
    })
  }

  Nil
}

// HELPERS ------------------------------------------------------------

fn generate_valid_address() {
  qcheck.bounded_int(0, 4095)
}

fn generate_valid_value() {
  qcheck.bounded_int(0, 255)
}

fn generate_invalid_address() {
  qcheck.from_generators(test_utils.int_ge(4096), [test_utils.int_lt(0)])
}
