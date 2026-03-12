import gleam/bit_array as ba
import gleam/option.{type Option, None, Some}
import gleam/result

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
      let new_b_a = ba.append(<<0:size(bits)>>, b_a)
      construct_bit_array_of_zeros_loop(n - 1, bits, new_b_a)
    }
  }
}

/// Returns a tuple of two bit arrays #(before, after) around an index:
/// -> input bit_array is of form <<..before, value at index, ..after>>
/// Assumes that the input BitArray contains 16 8-bit numbers.
fn split_bit_array_around(
  bit_array: BitArray,
  idx: Int,
) -> Result(#(BitArray, BitArray), Nil) {
  use before <- result.try(ba.slice(bit_array, 0, idx))
  use after <- result.try(ba.slice(
    bit_array,
    idx + 1,
    ba.byte_size(bit_array) - { idx + 1 },
  ))
  Ok(#(before, after))
}

/// Replaces the value contained at the indexed position
/// in a BitArray containing 8-bit numbers.
pub fn replace_bit_array_value_at(
  bit_array: BitArray,
  index idx: Int,
  with value: Int,
) -> Result(BitArray, Nil) {
  use #(before, after) <- result.try(bit_array |> split_bit_array_around(idx))
  Ok(before |> ba.append(<<value:8>>) |> ba.append(after))
}

/// Gets the value contained at indexed position
/// in a BitArray containing 8-bit numbers
pub fn get_bit_array_value_at(
  bit_array: BitArray,
  index idx: Int,
) -> Result(Int, Nil) {
  case ba.slice(bit_array, idx, 1) {
    Ok(<<value:8>>) -> Ok(value)
    _ -> Error(Nil)
  }
}
