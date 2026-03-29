import gleam/bool

/// A stack of up to 16 16-bit numbers
pub opaque type Stack {
  Stack(List(Int), length: Int)
}

pub type StackError {
  PushToFullStack
  ValueOverflow(Int)
  ValueUnderflow(Int)
  PopFromEmptyStack
}

pub fn new() {
  []
  |> Stack(length: 0)
}

pub fn push(stack: Stack, value: Int) -> Result(Stack, StackError) {
  let Stack(array, length) = stack
  use <- bool.guard(when: length >= 16, return: Error(PushToFullStack))
  use <- validate_value(value)

  [value, ..array] |> Stack(length: length + 1) |> Ok
}

pub fn pop(stack: Stack) -> Result(#(Int, Stack), StackError) {
  let Stack(array, length) = stack
  use <- bool.guard(when: length == 0, return: Error(PopFromEmptyStack))

  let assert [top, ..rest] = array

  #(top, Stack(rest, length - 1)) |> Ok
}

// VALIDATION ---------------------------------------------------------

fn validate_value(
  value: Int,
  func: fn() -> Result(a, StackError),
) -> Result(a, StackError) {
  use <- bool.guard(when: value < 0, return: Error(ValueUnderflow(value)))
  use <- bool.guard(when: value >= 65_536, return: Error(ValueOverflow(value)))
  func()
}
