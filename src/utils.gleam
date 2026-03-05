import gleam/int

pub type GetDigitError {
  InvalidIndex
  InvalidNumber
}

pub fn get_hex_digit(num: Int, idx: Int) -> Result(Int, GetDigitError) {
  case num, idx {
    _, idx if idx > 3 -> Error(InvalidIndex)
    num, _ if num > 0xFFFF -> Error(InvalidNumber)
    num, idx -> {
      let mask = 0b1111 |> int.bitwise_shift_left(12 - { 4 * idx })

      // todo
      let out =
        num
        |> int.bitwise_and(mask)
        |> int.bitwise_shift_right({ 3 - idx } * 4)

      Ok(out)
    }
  }
}
