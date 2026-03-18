pub opaque type Stack(a) {
  Stack(List(a))
}

pub fn new() -> Stack(a) {
  Stack([])
}

pub fn pop(stack: Stack(a)) -> #(Result(a, Nil), Stack(a)) {
  let Stack(list) = stack
  case list {
    [item, ..rest] -> #(Ok(item), Stack(rest))
    [] -> #(Error(Nil), stack)
  }
}

pub fn push(stack: Stack(a), item: a) -> Stack(a) {
  let Stack(list) = stack
  Stack([item, ..list])
}
