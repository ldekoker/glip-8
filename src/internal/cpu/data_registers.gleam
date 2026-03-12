import gleam/bit_array as ba
import gleam/option.{type Option, None, Some}
import gleam/result

pub opaque type DataRegisters {
  DataRegisters(values: BitArray)
}

pub fn new() -> DataRegisters {
  DataRegisters(<<
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
    0:8-unit(1),
  >>)
}

pub fn set_register(
  data_registers: DataRegisters,
  data_register_idx: Int,
  value: Int,
) -> Result(DataRegisters, Nil) {
  let DataRegisters(bit_array) = data_registers
  use new_bit_array <- result.try(
    bit_array
    |> replace_bit_array_value_at(index: data_register_idx, with: value),
  )

  Ok(DataRegisters(new_bit_array))
}

pub fn get_register(
  data_registers: DataRegisters,
  data_register_idx: Int,
) -> Result(Int, Nil) {
  let DataRegisters(bit_array) = data_registers
  bit_array |> get_bit_array_value_at(data_register_idx)
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
/// in a BitArray containing 16 8-bit numbers.
fn replace_bit_array_value_at(
  bit_array: BitArray,
  index idx: Int,
  with value: Int,
) -> Result(BitArray, Nil) {
  use #(before, after) <- result.try(bit_array |> split_bit_array_around(idx))
  Ok(before |> ba.append(<<value:8-unit(1)>>) |> ba.append(after))
}

/// Gets the value contained at indexed position
/// in a BitArray containing 16 8-bit numbers
fn get_bit_array_value_at(
  bit_array: BitArray,
  index idx: Int,
) -> Result(Int, Nil) {
  case ba.slice(bit_array, idx, 1) {
    Ok(<<value:8-unit(1)>>) -> Ok(value)
    _ -> Error(Nil)
  }
}
