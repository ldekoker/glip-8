import gleam/bool
import gleam/dict
import gleam/list
import gleam/pair
import gleam/result

/// # Keypad Memory
/// Two operations:
/// - get_pressed: Returns any of the currently pressed keys.
/// - is_pressed(key): Returns whether the given key is pressed.
/// - set_pressed(key, value): Sets the currently pressed key value.
/// 
/// Key indices are in [0, 15].
pub opaque type KeyPad {
  KeyPad(dict.Dict(Int, Bool))
}

pub type KeyPadError {
  TriedToAccessFakeKey(Int)
}

/// Return a new Keypad.
pub fn new() -> KeyPad {
  dict.new() |> KeyPad
}

/// Finds the first key currently being pressed.
/// Does not rely on order.
pub fn get_pressed(keypad: KeyPad) -> Result(Int, Nil) {
  let KeyPad(dict) = keypad
  dict
  |> dict.to_list
  |> list.filter(pair.second)
  |> list.map(pair.first)
  |> list.first
}

/// Find if the key is currently pressed.
/// If the key accessed is not in [0, 15] return KeyPadError.
pub fn is_pressed(keypad: KeyPad, key key: Int) -> Result(Bool, KeyPadError) {
  use <- validate_key(key)
  let KeyPad(dict) = keypad

  dict |> dict.get(key) |> result.unwrap(False) |> Ok
}

/// Updates the set flag for the given key.
pub fn set_pressed(
  keypad: KeyPad,
  key key: Int,
  value value: Bool,
) -> Result(KeyPad, KeyPadError) {
  use <- validate_key(key)

  let KeyPad(dict) = keypad

  dict |> dict.insert(for: key, insert: value) |> KeyPad |> Ok
}

// VALIDATION ---------------------------------------------------------

fn validate_key(
  key: Int,
  func: fn() -> Result(a, KeyPadError),
) -> Result(a, KeyPadError) {
  bool.guard(
    when: key < 0 || key >= 16,
    return: Error(TriedToAccessFakeKey(key)),
    otherwise: func,
  )
}
