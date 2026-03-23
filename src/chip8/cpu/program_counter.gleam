import gleam/bool

pub opaque type ProgramCounter {
  ProgramCounter(Int)
}

pub type ProgramCounterError {
  ValueOverflow(Int)
}

pub fn new() {
  0 |> ProgramCounter |> Ok
}

pub fn set_value(program_counter: ProgramCounter, value: Int) {
  use <- bool.guard(when: value >= 4096, return: Error(ValueOverflow(value)))
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

  use <- bool.guard(
    when: new_value >= 4096,
    return: Error(ValueOverflow(new_value)),
  )
  new_value |> ProgramCounter |> Ok
}
