import gleam/int
import gleam/io
import gleam/result
import utils

pub fn main() {
  echo 0xFFFF
  use m <- result.try(utils.get_hex_digit(0xAF12, 0))
  echo m
  Ok(Nil)
}
