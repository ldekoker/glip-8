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
