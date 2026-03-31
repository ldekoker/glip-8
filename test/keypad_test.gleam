import chip8/cpu/keypad
import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import qcheck
import test_utils

pub fn keypad_functions_test() {
  let keypad = keypad.new()
  use valid_key <- qcheck.given(valid_key_generator())

  let assert Error(Nil) = keypad |> keypad.get_pressed

  let assert Ok(False) = keypad |> keypad.is_pressed(valid_key)

  let assert Ok(new_keypad) = keypad |> keypad.set_pressed(valid_key, True)
  let assert Ok(True) = new_keypad |> keypad.is_pressed(valid_key)
  let assert Ok(pressed_key) = new_keypad |> keypad.get_pressed()
  assert valid_key == pressed_key
  Nil
}

pub fn keypad_invalid_access_test() {
  let keypad = keypad.new()
  use invalid_key <- qcheck.given(invalid_key_generator())

  let assert Error(keypad.TriedToAccessFakeKey(key)) =
    keypad |> keypad.is_pressed(invalid_key)
  assert key == invalid_key

  Nil
}

pub fn setting_one_key_does_not_change_others_test() {
  use keypad <- qcheck.given(keypad_generator())
  use key <- qcheck.given(valid_key_generator())

  let assert Ok(new_keypad) =
    keypad
    |> keypad.set_pressed(key, bool.negate(keypad |> is_pressed(key)))

  assert new_keypad |> is_pressed(key) != keypad |> is_pressed(key)
  assert int.range(0, 16, True, fn(true_so_far, index) {
    case index == key {
      True -> true_so_far
      False -> new_keypad |> is_pressed(index) == keypad |> is_pressed(index)
    }
  })
}

// HELPERS ------------------------------------------------------------

fn is_pressed(keypad: keypad.KeyPad, key: Int) -> Bool {
  keypad |> keypad.is_pressed(key) |> result.lazy_unwrap(fn() { panic })
}

fn keypad_generator() -> qcheck.Generator(keypad.KeyPad) {
  use bools: List(Bool) <- qcheck.map(qcheck.fixed_length_list_from(
    qcheck.bool(),
    16,
  ))
  use keypad, value, key <- list.index_fold(bools, keypad.new())
  let assert Ok(new_keypad) = keypad |> keypad.set_pressed(key, value)
  new_keypad
}

fn valid_key_generator() -> qcheck.Generator(Int) {
  qcheck.bounded_int(0, 15)
}

fn invalid_key_generator() {
  qcheck.from_generators(test_utils.int_lt(0), [test_utils.int_ge(16)])
}
