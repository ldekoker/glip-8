import chip8/cpu/fixed_length_bit_array
import gleam/result

pub opaque type KeyPad {
  KeyPad(fixed_length_bit_array.FixedLengthBitArray)
}

pub type KeyPadError {
  FailedToInitialise
  TriedToAccessFakeKey(Int)
}

pub fn new() -> Result(KeyPad, KeyPadError) {
  fixed_length_bit_array.new(length: 16, bits: 1)
  |> result.map(KeyPad)
  |> result.replace_error(FailedToInitialise)
}

pub fn get_pressed(keypad: KeyPad) -> Result(Int, Nil) {
  let KeyPad(array) = keypad
  array |> fixed_length_bit_array.find_index(fn(num) { num == 1 })
}

pub fn is_pressed(keypad: KeyPad, key key: Int) -> Result(Bool, KeyPadError) {
  let KeyPad(array) = keypad

  array
  |> fixed_length_bit_array.get_value_at_address(key)
  |> result.map(fn(num) { num == 1 })
  |> result.replace_error(TriedToAccessFakeKey(key))
}
