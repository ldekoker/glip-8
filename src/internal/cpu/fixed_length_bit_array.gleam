import gleam/bit_array
import gleam/bool
import gleam/float
import gleam/int
import gleam/result

pub opaque type FixedLengthBitArray {
  FixedLengthBitArray(bit_array: BitArray, bit_length: Int, length: Int)
}

pub type FixedLengthBitArrayError {
  BadAddress(address: Int)
  ValueOverflow(value: Int)
  NonPositiveBitLength(bit_length: Int)
}

/// Returns a new Fixed Length Bit Array
pub fn new(
  length length: Int,
  bits bit_length: Int,
) -> Result(FixedLengthBitArray, FixedLengthBitArrayError) {
  use <- bool.guard(
    when: bit_length <= 0,
    return: Error(NonPositiveBitLength(bit_length:)),
  )

  Ok(FixedLengthBitArray(
    bit_array: construct_bit_array_of_zeros(length: length, bits: bit_length),
    length:,
    bit_length:,
  ))
}

pub fn get_value_at_address(
  fl_bit_array: FixedLengthBitArray,
  address: Int,
) -> Result(Int, FixedLengthBitArrayError) {
  let FixedLengthBitArray(bytes, ..) = fl_bit_array
  bytes
  |> get_bit_array_value_at(address)
  |> result.replace_error(BadAddress(address:))
}

pub fn set_value_at_address(
  fl_bit_array: FixedLengthBitArray,
  address: Int,
  value: Int,
) -> Result(FixedLengthBitArray, FixedLengthBitArrayError) {
  use max_value_representable <- result.try(get_max_representable_value(
    fl_bit_array,
  ))

  case value, value % max_value_representable {
    value, truncated_value if value != truncated_value -> {
      Error(ValueOverflow(value:))
    }
    _, _ -> {
      let FixedLengthBitArray(bytes, ..) = fl_bit_array
      use new_bytes <- result.try(
        bytes
        |> replace_bit_array_value_at(
          address,
          with: value,
          bit_length: fl_bit_array.bit_length,
        )
        |> result.replace_error(BadAddress(address:)),
      )

      Ok(FixedLengthBitArray(
        new_bytes,
        length: fl_bit_array.length,
        bit_length: fl_bit_array.bit_length,
      ))
    }
  }
}

fn get_max_representable_value(
  fl_bit_array: FixedLengthBitArray,
) -> Result(Int, FixedLengthBitArrayError) {
  2
  |> int.power(of: fl_bit_array.bit_length |> int.to_float)
  |> result.map(float.truncate)
  |> result.replace_error(NonPositiveBitLength(
    bit_length: fl_bit_array.bit_length,
  ))
}

pub fn get_bit_array(fl_bit_array: FixedLengthBitArray) -> BitArray {
  fl_bit_array.bit_array
}

/// Replaces the value contained at the indexed position
/// in a BitArray containing 8-bit numbers.
fn replace_bit_array_value_at(
  bit_array: BitArray,
  index idx: Int,
  with value: Int,
  bit_length bit_length: Int,
) -> Result(BitArray, Nil) {
  use #(before, after) <- result.try(bit_array |> split_bit_array_around(idx))
  Ok(
    before
    |> bit_array.append(<<value:size(bit_length)>>)
    |> bit_array.append(after),
  )
}

fn construct_bit_array_of_zeros(length n: Int, bits bits: Int) {
  construct_bit_array_of_zeros_loop(n, bits, <<>>)
}

fn construct_bit_array_of_zeros_loop(n: Int, bits: Int, b_a: BitArray) {
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

/// Returns a tuple of two bit arrays #(before, after) around an index:
/// -> input bit_array is of form <<..before, value at index, ..after>>
/// Assumes that the input BitArray contains 16 8-bit numbers.
fn split_bit_array_around(
  bit_array: BitArray,
  idx: Int,
) -> Result(#(BitArray, BitArray), Nil) {
  use before <- result.try(bit_array.slice(bit_array, 0, idx))
  use after <- result.try(bit_array.slice(
    bit_array,
    idx + 1,
    bit_array.byte_size(bit_array) - { idx + 1 },
  ))
  Ok(#(before, after))
}

/// Gets the value contained at indexed position
/// in a BitArray containing 8-bit numbers
fn get_bit_array_value_at(
  bit_array: BitArray,
  index idx: Int,
) -> Result(Int, Nil) {
  case bit_array.slice(bit_array, idx, 1) {
    Ok(<<value:8>>) -> Ok(value)
    _ -> Error(Nil)
  }
}
