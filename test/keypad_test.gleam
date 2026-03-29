import chip8/cpu/keypad
import gleam/result

pub fn keypad_test() {
  let keypad = keypad.new()

  let assert Error(Nil) = keypad |> keypad.get_pressed

  let assert Ok(False) = keypad |> keypad.is_pressed(0)
  let assert Ok(False) = keypad |> keypad.is_pressed(9)

  Ok(Nil)
}

pub fn invalid_key_test() {
  let keypad = keypad.new()

  let assert Error(keypad.TriedToAccessFakeKey(-1)) =
    keypad |> keypad.is_pressed(-1)
  let assert Error(keypad.TriedToAccessFakeKey(16)) =
    keypad |> keypad.is_pressed(16)
}
