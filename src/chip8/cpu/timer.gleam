import gleam/bool

pub opaque type Timer {
  Timer(current: Int)
}

pub type TimerError {
  ValueOverflow(Int)
  ValueUnderflow(Int)
}

pub fn new() -> Result(Timer, TimerError) {
  Timer(0) |> Ok
}

pub fn get_value(timer: Timer) -> Int {
  timer.current
}

pub fn set_value(_: Timer, new_value: Int) -> Result(Timer, TimerError) {
  use <- validate_value(new_value)
  Timer(new_value) |> Ok
}

pub fn tick(timer: Timer) -> Result(Timer, TimerError) {
  let Timer(current) = timer
  case current - 1 {
    n if n >= 0 -> Timer(n) |> Ok
    _ -> Timer(0) |> Ok
  }
}

// HELPERS ------------------------------------------------------------

fn validate_value(value, func) -> Result(Timer, TimerError) {
  use <- bool.guard(when: value >= 256, return: Error(ValueOverflow(value)))
  use <- bool.guard(when: value < 0, return: Error(ValueUnderflow(value)))
  func()
}
