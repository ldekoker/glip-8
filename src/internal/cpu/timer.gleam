pub opaque type Timer {
  Timer(current: Int)
}

pub fn new() -> Timer {
  Timer(0)
}

pub fn get_value(timer: Timer) -> Int {
  timer.current
}

pub fn set_value(timer: Timer, new_value: Int) -> Timer {
  Timer(new_value)
}

pub fn tick(timer: Timer) -> Timer {
  let Timer(current) = timer
  case current - 1 {
    n if n >= 0 -> Timer(n)
    _ -> Timer(0)
  }
}
