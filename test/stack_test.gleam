import chip8/cpu/stack
import gleam/list
import gleam/result

pub fn stack_test() {
  use stack_nums <- result.try(
    stack.new()
    |> Ok
    |> result.try(stack.push(_, 1))
    |> result.try(stack.push(_, 2))
    |> result.try(stack.push(_, 3)),
  )

  let assert Ok(#(top, current_stack)) = stack.pop(stack_nums)
  let assert Ok(#(middle, current_stack)) = stack.pop(current_stack)
  let assert Ok(#(bottom, _)) = stack.pop(current_stack)

  assert top == 3
  assert middle == 2
  assert bottom == 1
  Ok(Nil)
}

pub fn empty_stack_test() {
  let empty_stack = stack.new()

  let error = empty_stack |> stack.pop
  assert error == Error(stack.PopFromEmptyStack)
}

pub fn full_stack_test() {
  let stack = stack.new()
  let assert Error(stack.PushToFullStack) =
    list.try_fold(
      over: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      from: stack,
      with: fn(stack, num) { stack |> stack.push(num) },
    )
}

pub fn stack_value_overflow_test() {
  let stack = stack.new()

  let assert Error(stack.ValueOverflow(65_536)) = stack |> stack.push(65_536)
}
