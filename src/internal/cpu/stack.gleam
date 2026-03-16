type Stack(a) =
  List(a)

pub fn new() -> Stack(a) {
  []
}

pub fn pop(stack: Stack(a)) -> #(Result(a, Nil), Stack(a)) {
  case stack {
    [item, ..rest] -> #(Ok(item), rest)
    [] -> #(Error(Nil), stack)
  }
}

pub fn push(stack: Stack(a), item: a) -> Stack(a) {
  [item, ..stack]
}
