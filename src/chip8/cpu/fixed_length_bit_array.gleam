import gleam/bit_array
import gleam/bool
import gleam/float
import gleam/int
import gleam/order
import gleam/result

pub opaque type ByteArray {
  ByteArray(bit_array: BitArray, byte_length: Int, length: Int)
}

pub type ByteArrayError {
  BadAddress(address: Int)
  ValueOverflow(value: Int)
  ValueUnderflow(value: Int)
  NonPositiveByteLength(byte_length: Int)
}

/// Returns a new Fixed Length Bit Array
pub fn new(
  length length: Int,
  bytes byte_length: Int,
) -> Result(ByteArray, ByteArrayError) {
  use <- bool.guard(
    when: byte_length <= 0,
    return: Error(NonPositiveByteLength(byte_length:)),
  )

  Ok(ByteArray(
    bit_array: construct_bit_array_of_zeros(
      length: length,
      bits: byte_length * 8,
    ),
    length:,
    byte_length:,
  ))
}

pub fn get_value_at_address(
  fl_bit_array: ByteArray,
  address: Int,
) -> Result(Int, ByteArrayError) {
  let ByteArray(bytes, ..) = fl_bit_array
  bytes
  |> get_bit_array_value_at(address, fl_bit_array.byte_length)
  |> result.replace_error(BadAddress(address:))
}

pub fn set_value_at_address(
  fl_bit_array: ByteArray,
  address: Int,
  value: Int,
) -> Result(ByteArray, ByteArrayError) {
  use max_value_representable <- result.try(get_max_representable_value(
    fl_bit_array,
  ))

  let is_truncated = fn(num) {
    case num >= 0, num < max_value_representable {
      True, True -> order.Eq
      True, False -> order.Gt
      False, True -> order.Lt
      _, _ -> panic as "unreachable"
    }
  }

  case is_truncated(value) {
    order.Gt -> Error(ValueOverflow(value:))
    order.Lt -> Error(ValueUnderflow(value:))
    order.Eq -> {
      let ByteArray(bytes, ..) = fl_bit_array
      use new_bytes <- result.try(
        bytes
        |> replace_bit_array_value_at(
          address,
          with: value,
          byte_length: fl_bit_array.byte_length,
        )
        |> result.replace_error(BadAddress(address:)),
      )

      Ok(ByteArray(
        new_bytes,
        length: fl_bit_array.length,
        byte_length: fl_bit_array.byte_length,
      ))
    }
  }
}

fn get_max_representable_value(
  fl_bit_array: ByteArray,
) -> Result(Int, ByteArrayError) {
  2
  |> int.power(of: { fl_bit_array.byte_length * 8 } |> int.to_float)
  |> result.map(float.truncate)
  |> result.replace_error(NonPositiveByteLength(
    byte_length: fl_bit_array.byte_length,
  ))
}

pub fn get_bit_array(fl_bit_array: ByteArray) -> BitArray {
  fl_bit_array.bit_array
}

/// Replaces the value contained at the indexed position
/// in a BitArray containing 8-bit numbers.
fn replace_bit_array_value_at(
  bit_array: BitArray,
  index idx: Int,
  with value: Int,
  byte_length byte_length: Int,
) -> Result(BitArray, Nil) {
  use #(before, after) <- result.try(
    bit_array |> split_bit_array_around(idx, byte_length),
  )
  Ok(
    before
    |> bit_array.append(<<value:size({ 8 * byte_length })>>)
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
fn split_bit_array_around(
  bit_array: BitArray,
  idx: Int,
  byte_length: Int,
) -> Result(#(BitArray, BitArray), Nil) {
  let start = idx * byte_length
  let end = { idx + 1 } * byte_length
  let ba_length = bit_array.byte_size(bit_array)
  use before <- result.try(bit_array.slice(bit_array, 0, start))
  use after <- result.try(bit_array.slice(bit_array, end, ba_length - end))
  Ok(#(before, after))
}

/// Gets the value contained at indexed position
/// in a BitArray containing 8-bit numbers
fn get_bit_array_value_at(
  bit_array: BitArray,
  idx: Int,
  byte_length: Int,
) -> Result(Int, Nil) {
  let start = idx * byte_length
  case bit_array.slice(bit_array, start, byte_length) {
    Ok(<<value:size({ 8 * byte_length })>>) -> Ok(value)
    _ -> Error(Nil)
  }
}

/// Find the first index in the ByteArray who's element
/// makes the callback True.
pub fn find_index(
  in fl_bit_array: ByteArray,
  one_that is_desired: fn(Int) -> Bool,
) -> Result(Int, Nil) {
  find_index_loop(fl_bit_array, is_desired, 0)
}

fn find_index_loop(
  fl_bit_array: ByteArray,
  is_desired: fn(Int) -> Bool,
  index: Int,
) -> Result(Int, Nil) {
  use value_at_index <- result.try(
    get_value_at_address(fl_bit_array, index) |> result.replace_error(Nil),
  )
  case is_desired(value_at_index) {
    True -> Ok(index)
    False -> {
      find_index_loop(fl_bit_array, is_desired, index + 1)
    }
  }
}
