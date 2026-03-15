import gleam/bool
import gleam/float
import gleam/int
import gleam/result
import utils

pub opaque type FixedLengthBitArray {
  FixedLengthBitArray(bit_array: BitArray, bit_length: Int, length: Int)
}

pub type FixedLengthBitArrayError {
  BadAddress(address: Int)
  ValueOverflow(value: Int)
  NonPositiveBitLength(bit_length: Int)
}

pub fn new(
  length length: Int,
  bits bit_length: Int,
) -> Result(FixedLengthBitArray, FixedLengthBitArrayError) {
  use <- bool.guard(
    when: bit_length > 0,
    return: Error(NonPositiveBitLength(bit_length:)),
  )

  Ok(FixedLengthBitArray(
    bit_array: utils.construct_bit_array_of_zeros(
      length: length,
      bits: bit_length,
    ),
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
  |> utils.get_bit_array_value_at(address)
  |> result.replace_error(BadAddress(address:))
}

pub fn set_value_at_address(
  fl_bit_array: FixedLengthBitArray,
  address: Int,
  value: Int,
) -> Result(FixedLengthBitArray, FixedLengthBitArrayError) {
  use max_value_representable <- result.try({
    2
    |> int.power(of: fl_bit_array.bit_length |> int.to_float)
    |> result.map(float.truncate)
    |> result.replace_error(NonPositiveBitLength(
      bit_length: fl_bit_array.bit_length,
    ))
  })

  case value, value % max_value_representable {
    value, truncated_value if value != truncated_value -> {
      Error(ValueOverflow(value:))
    }
    _, _ -> {
      let FixedLengthBitArray(bytes, ..) = fl_bit_array
      use new_bytes <- result.try(
        bytes
        |> utils.replace_bit_array_value_at(address, with: value)
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

pub fn get_bit_array(fl_bit_array: FixedLengthBitArray) -> BitArray {
  fl_bit_array.bit_array
}
