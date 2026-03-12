import gleam/list

pub opaque type DisplayBuffer {
  DisplayBuffer(memory: BitArray)
}

pub fn new() -> DisplayBuffer {
  DisplayBuffer(<<
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
    0:64,
  >>)
}

/// Transforms a DisplayBuffer into a nested list of Boolean values.
/// Always outputs a list of 32 lists of 64 booleans.
pub fn to_display(buf: DisplayBuffer) -> List(List(Bool)) {
  let DisplayBuffer(bits) = buf
  bits |> bit_array_to_list_of_bits |> list.sized_chunk(into: 64)
}

/// Recursively transform a BitArray into a list of Booleans.
/// TCO-optimised.
fn bit_array_to_list_of_bits(bits: BitArray) -> List(Bool) {
  bit_array_to_list_of_bits_loop(bits, [])
}

fn bit_array_to_list_of_bits_loop(
  bits: BitArray,
  bools: List(Bool),
) -> List(Bool) {
  case bits {
    <<first_bit:1, rest:bits>> -> {
      let new_bools = [first_bit == 1, ..bools]
      bit_array_to_list_of_bits_loop(rest, new_bools)
    }
    _ -> list.reverse(bools)
  }
}
