import gleam/int
import gleam/result
import gleeunit
import utils

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn extract_hex_digit_test() {
  use a <- result.try(utils.get_hex_digit(0xAF12, 0))
  use f <- result.try(utils.get_hex_digit(0xAF12, 1))
  use one <- result.try(utils.get_hex_digit(0xAF12, 2))
  use two <- result.try(utils.get_hex_digit(0xAF12, 3))

  assert int.to_base16(a) == "A"
  assert int.to_base16(f) == "F"
  assert int.to_base16(one) == "1"
  assert int.to_base16(two) == "2"
  Ok(Nil)
}
