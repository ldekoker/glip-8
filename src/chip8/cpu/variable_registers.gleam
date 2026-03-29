import gleam/bool
import gleam/dict
import gleam/result

/// Sixteen 8-bit registers.
pub opaque type VariableRegisters {
  VariableRegisters(dict.Dict(Int, Int))
}

pub type VariableRegistersError {
  ValueOverflow(Int)
  ValueUnderflow(Int)
  TriedToAccessFakeRegister(Int)
}

pub fn new() {
  dict.new() |> VariableRegisters
}

/// Sets value of given register.
pub fn set_value(
  variable_registers: VariableRegisters,
  at vx: Int,
  to value: Int,
) {
  use <- validate_value(value)
  use <- validate_register(vx)
  let VariableRegisters(dict) = variable_registers

  dict |> dict.insert(vx, value) |> VariableRegisters |> Ok
}

/// Gets value of given register.
/// If register is valid but unset, returns 0.
pub fn get_value(variable_registers: VariableRegisters, at vx: Int) {
  use <- validate_register(vx)
  let VariableRegisters(dict) = variable_registers

  dict |> dict.get(vx) |> result.unwrap(0) |> Ok
}

// VALIDATION ---------------------------------------------------------

fn validate_value(
  value: Int,
  func: fn() -> Result(a, VariableRegistersError),
) -> Result(a, VariableRegistersError) {
  use <- bool.guard(when: value >= 256, return: Error(ValueOverflow(value)))
  use <- bool.guard(value < 0, Error(ValueUnderflow(value)))
  func()
}

fn validate_register(
  register: Int,
  func: fn() -> Result(a, VariableRegistersError),
) -> Result(a, VariableRegistersError) {
  use <- bool.guard(
    when: register < 0 || register >= 16,
    return: Error(TriedToAccessFakeRegister(register)),
  )
  func()
}
