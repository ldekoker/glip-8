import gleam/result
import utils

pub opaque type DataRegisters {
  DataRegisters(values: BitArray)
}

pub fn new() -> DataRegisters {
  DataRegisters(utils.construct_bit_array_of_zeros(length: 16, bits: 8))
}

pub fn set_register(
  data_registers: DataRegisters,
  data_register_idx: Int,
  value: Int,
) -> Result(DataRegisters, Nil) {
  let DataRegisters(bit_array) = data_registers
  use new_bit_array <- result.try(
    bit_array
    |> utils.replace_bit_array_value_at(index: data_register_idx, with: value),
  )

  Ok(DataRegisters(new_bit_array))
}

pub fn get_register(
  data_registers: DataRegisters,
  data_register_idx: Int,
) -> Result(Int, Nil) {
  let DataRegisters(bit_array) = data_registers
  bit_array |> utils.get_bit_array_value_at(data_register_idx)
}
