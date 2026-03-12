import gleam/result
import utils

pub opaque type AddressRegister {
  AddressRegister(value: BitArray)
}

pub fn new() {
  AddressRegister(value: utils.construct_bit_array_of_zeros(length: 1, bits: 16))
}

pub fn set_value(
  reg: AddressRegister,
  value: Int,
) -> Result(AddressRegister, Nil) {
  let AddressRegister(old_value) = reg
  use new_bit_array <- result.try(
    old_value |> utils.replace_bit_array_value_at(index: 0, with: value),
  )
  Ok(AddressRegister(new_bit_array))
}

pub fn get_value(reg: AddressRegister) -> Result(Int, Nil) {
  let AddressRegister(value) = reg
  value |> utils.get_bit_array_value_at(0)
}
