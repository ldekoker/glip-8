pub opaque type Timer {
  Timer(current: Int)
}

pub fn new(value: Int) -> Timer {
  Timer(value)
}
