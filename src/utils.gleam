import gleam/bit_array as ba
import gleam/result

pub fn split_16_bit_to_hexadecimal(
  num: Int,
) -> Result(#(Int, Int, Int, Int), Nil) {
  case <<num:16-unit(1)>> {
    <<a:4, b:4, c:4, d:4>> -> Ok(#(a, b, c, d))
    _ -> Error(Nil)
  }
}
