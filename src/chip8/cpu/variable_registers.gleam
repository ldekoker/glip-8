import chip8/cpu/fixed_length_bit_array
import gleam/result

/// Sixteen 8-bit registers.
pub opaque type VariableRegisters {
  VariableRegisters(fixed_length_bit_array.ByteArray)
}

pub type VariableRegistersError {
  FailedToInitialise
  FailedToSetV(Int)
  FailedToGetFromV(Int)
}

pub fn new() {
  fixed_length_bit_array.new(length: 16, bytes: 1)
  |> result.replace_error(FailedToInitialise)
  |> result.map(VariableRegisters)
}

pub fn set_value(
  variable_registers: VariableRegisters,
  at vx: Int,
  to value: Int,
) {
  let VariableRegisters(array) = variable_registers
  array
  |> fixed_length_bit_array.set_value_at_address(vx, value % 256)
  |> result.map(VariableRegisters)
  |> result.replace_error(FailedToSetV(vx))
}

pub fn get_value(variable_registers: VariableRegisters, at vx: Int) {
  let VariableRegisters(array) = variable_registers
  array
  |> fixed_length_bit_array.get_value_at_address(vx)
  |> result.replace_error(FailedToGetFromV(vx))
}
