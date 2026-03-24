import chip8/cpu/fixed_length_bit_array
import gleam/bool
import gleam/result

/// A stack of up to 16 16-bit numbers
pub opaque type Stack {
  Stack(fixed_length_bit_array.ByteArray, length: Int)
}

pub type StackError {
  FailedToInitialise
  PushToFullStack
  ValueOverflow(Int)
  ValueUnderflow(Int)
  ArrayError(fixed_length_bit_array.ByteArrayError)
  PopFromEmptyStack
}

pub fn new() {
  fixed_length_bit_array.new(16, 2)
  |> result.replace_error(FailedToInitialise)
  |> result.map(Stack(_, length: 0))
}

pub fn push(stack: Stack, value: Int) -> Result(Stack, StackError) {
  let Stack(array, length) = stack
  use <- bool.guard(when: length >= 16, return: Error(PushToFullStack))

  use new_array <- result.try(
    array
    |> fixed_length_bit_array.set_value_at_address(length, value)
    |> result.map_error(from_fl_ba_error),
  )

  Stack(new_array, length + 1) |> Ok
}

pub fn pop(stack: Stack) -> Result(#(Int, Stack), StackError) {
  let Stack(array, length) = stack
  use <- bool.guard(when: length == 0, return: Error(PopFromEmptyStack))

  use popped_value <- result.try(
    array
    |> fixed_length_bit_array.get_value_at_address(length - 1)
    |> result.map_error(from_fl_ba_error),
  )

  #(popped_value, Stack(array, length - 1)) |> Ok
}

fn from_fl_ba_error(error: fixed_length_bit_array.ByteArrayError) -> StackError {
  case error {
    fixed_length_bit_array.BadAddress(_) -> PushToFullStack
    fixed_length_bit_array.ValueOverflow(value) -> ValueOverflow(value)
    e -> ArrayError(e)
  }
}
