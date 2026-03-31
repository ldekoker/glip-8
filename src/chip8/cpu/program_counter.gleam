import gleam/bool

/// A 12-bit program counter.
pub opaque type ProgramCounter {
  ProgramCounter(Int)
}

pub type ProgramCounterError {
  ValueOverflow(Int)
  ValueUnderflow(Int)
}

pub fn new() {
  0 |> ProgramCounter |> Ok
}

pub fn set_value(program_counter: ProgramCounter, value: Int) {
  use <- validate_value(value)
  let ProgramCounter(_) = program_counter
  value |> ProgramCounter |> Ok
}

pub fn get_value(program_counter: ProgramCounter) -> Int {
  let ProgramCounter(value) = program_counter
  value
}

pub fn increment_by(program_counter: ProgramCounter, int: Int) {
  let ProgramCounter(value) = program_counter

  let new_value = value + int

  use <- validate_value(new_value)
  new_value |> ProgramCounter |> Ok
}

// HELPERS ------------------------------------------------------------
fn validate_value(value, func) {
  use <- bool.guard(when: value >= 4096, return: Error(ValueOverflow(value)))
  use <- bool.guard(when: value < 0, return: Error(ValueUnderflow(value)))
  func()
}
