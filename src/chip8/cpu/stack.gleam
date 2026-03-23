import chip8/cpu/fixed_length_bit_array
import chip8/cpu/program_counter
import gleam/bool
import gleam/result

pub opaque type Stack {
  Stack(fixed_length_bit_array.FixedLengthBitArray, length: Int)
}

pub type StackError {
  FailedToInitialise
  PushToFullStack
  ValueOverflow(Int)
  ArrayError(fixed_length_bit_array.FixedLengthBitArrayError)
  PopFromEmptyStack
}

pub fn new() {
  fixed_length_bit_array.new(16, 16)
  |> result.replace_error(FailedToInitialise)
  |> result.map(Stack(_, length: 16))
}

pub fn push(
  stack: Stack,
  old_pc: program_counter.ProgramCounter,
) -> Result(Stack, StackError) {
  let Stack(array, length) = stack
  use <- bool.guard(when: length >= 16, return: Error(PushToFullStack))

  let pc_value = program_counter.get_value(old_pc)

  use new_array <- result.try(
    array
    |> fixed_length_bit_array.set_value_at_address(length, pc_value)
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

fn from_fl_ba_error(
  error: fixed_length_bit_array.FixedLengthBitArrayError,
) -> StackError {
  case error {
    fixed_length_bit_array.BadAddress(_) -> PushToFullStack
    fixed_length_bit_array.ValueOverflow(value) -> ValueOverflow(value)
    e -> ArrayError(e)
  }
}
