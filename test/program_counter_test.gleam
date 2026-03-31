import chip8/cpu/program_counter
import gleam/result
import qcheck
import test_utils

pub fn program_counter_test() {
  let assert Ok(pc) = program_counter.new()
  use valid_value <- qcheck.given(generate_valid_value())

  let assert Ok(pc) = pc |> program_counter.set_value(valid_value)
  let assert Ok(_) = pc |> program_counter.increment_by(4095 - valid_value)

  Nil
}

pub fn pc_bad_value_test() {
  let assert Ok(pc) = program_counter.new()
  use bad_value <- qcheck.given(generate_invalid_value())

  let assert Error(_) = pc |> program_counter.set_value(bad_value)

  Nil
}

pub fn pc_bad_increment_test() {
  let assert Ok(pc) = program_counter.new()
  use good_value <- qcheck.given(generate_valid_value())
  use bad_increment <- qcheck.given(test_utils.int_ge(4096))

  let assert Error(_) =
    pc
    |> program_counter.set_value(good_value)
    |> result.try(program_counter.increment_by(_, bad_increment))

  Nil
}

// HELPERS ------------------------------------------------------------
fn generate_valid_value() {
  qcheck.bounded_int(0, 4095)
}

fn generate_invalid_value() {
  qcheck.from_generators(test_utils.int_ge(4096), [test_utils.int_lt(0)])
}
