import gleam/bit_array
import gleam/option.{type Option, None, Some}

pub fn split_16_bit_to_hexadecimal(num: Int) -> Option(#(Int, Int, Int, Int)) {
  case <<num:16-unit(1)>> {
    <<a:4, b:4, c:4, d:4>> -> Some(#(a, b, c, d))
    _ -> None
  }
}

pub fn construct_bit_array_of_zeros(length n: Int, bits bits: Int) {
  construct_bit_array_of_zeros_loop(n, bits, <<>>)
}

pub fn construct_bit_array_of_zeros_loop(n: Int, bits: Int, b_a: BitArray) {
  case n {
    0 -> {
      b_a
    }
    n -> {
      let new_b_a = bit_array.append(<<0:size(bits)>>, b_a)
      construct_bit_array_of_zeros_loop(n - 1, bits, new_b_a)
    }
  }
}
