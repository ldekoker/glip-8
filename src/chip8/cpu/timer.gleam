import gleam/bool

pub opaque type Timer {
  Timer(current: Int)
}

pub type TimerError {
  ValueOverflow(Int)
}

pub fn new() -> Result(Timer, TimerError) {
  Timer(0) |> Ok
}

pub fn get_value(timer: Timer) -> Int {
  timer.current
}

pub fn set_value(_: Timer, new_value: Int) -> Result(Timer, TimerError) {
  use <- bool.guard(
    when: new_value >= 256,
    return: Error(ValueOverflow(new_value)),
  )
  Timer(new_value) |> Ok
}

pub fn tick(timer: Timer) -> Result(Timer, TimerError) {
  let Timer(current) = timer
  case current - 1 {
    n if n >= 0 -> Timer(n) |> Ok
    _ -> Timer(0) |> Ok
  }
}
