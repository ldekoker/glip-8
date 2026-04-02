import chip8/instructions
import gleam/bit_array
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(rom_data) =
    simplifile.read_bits(from: "./src/playground/assets/corax_tests.ch8")
    |> result.map(bit_array.base16_encode)
    |> result.map(string.to_graphemes)
    |> result.map(list.sized_chunk(_, 2))
    |> result.map(list.map(_, string.join(_, "")))
    |> result.replace_error(Nil)
    |> result.try(fn(strings) {
      list.map(strings, int.base_parse(_, 16)) |> result.all
    })

  echo rom_data
}
