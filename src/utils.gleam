import gleam/option.{type Option, None, Some}

pub fn split_16_bit_to_hexadecimal(num: Int) -> Option(#(Int, Int, Int, Int)) {
  case <<num:16-unit(1)>> {
    <<a:4, b:4, c:4, d:4>> -> Some(#(a, b, c, d))
    _ -> None
  }
}
