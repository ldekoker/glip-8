import gleam/option.{Some}
import gleeunit
import utils

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn split_hex_digit_test_constructor(
  input: Int,
  correct: #(Int, Int, Int, Int),
) -> Bool {
  let result = utils.split_16_bit_to_hexadecimal(input)
  case result {
    Some(#(a, b, c, d)) -> {
      #(a, b, c, d) == correct
    }
    _ -> {
      False
    }
  }
}

pub fn split_hex_digit_test() {
  assert split_hex_digit_test_constructor(0xABCD, #(0xA, 0xB, 0xC, 0xD))
  assert split_hex_digit_test_constructor(0x0000, #(0x0, 0x0, 0x0, 0x0))
  assert split_hex_digit_test_constructor(0xABCD1, #(0xB, 0xC, 0xD, 0x1))
  assert split_hex_digit_test_constructor(0xF0000, #(0x0, 0x0, 0x0, 0x0))
}
