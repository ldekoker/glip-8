import internal/cpu/stack

pub fn stack_test() {
  let stack_nums =
    stack.new() |> stack.push(1) |> stack.push(2) |> stack.push(3)
  let #(top, current_stack) = stack.pop(stack_nums)
  let #(bottom, _) =
    current_stack
    |> stack.pop()
    |> fn(pair) {
      let #(_, stack) = pair
      stack
    }
    |> stack.pop()
  assert top == Ok(3)
  assert bottom == Ok(1)
}

pub fn empty_stack_test() {
  let empty_stack = stack.new()

  let #(nil, _) = empty_stack |> stack.pop()
  assert nil == Error(Nil)
}
