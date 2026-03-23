import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair

// A 64x32 display buffer.
pub opaque type DisplayBuffer {
  DisplayBuffer(dict.Dict(#(Int, Int), Bool))
}

pub type DisplayBufferError {
  TriedToAccessFakeRow(Int)
}

pub fn new() -> Result(DisplayBuffer, DisplayBufferError) {
  int.range(from: 0, to: 32, with: dict.new(), run: fn(map, y_coord) {
    int.range(from: 0, to: 64, with: map, run: fn(map, x_coord) {
      let point = #(x_coord, y_coord)
      map |> dict.insert(point, False)
    })
  })
  |> DisplayBuffer
  |> Ok
}

pub fn get_row(
  display_buffer: DisplayBuffer,
  row: Int,
) -> Result(List(Bool), DisplayBufferError) {
  use <- bool.guard(when: row >= 32, return: Error(TriedToAccessFakeRow(row)))
  let DisplayBuffer(map) = display_buffer

  map
  |> dict.to_list
  |> list.filter(fn(pair) { { pair |> pair.first |> pair.second } == row })
  |> list.sort(by: fn(paira, pairb) {
    let a_x = paira |> pair.first |> pair.first
    let b_x = pairb |> pair.first |> pair.first

    int.compare(a_x, b_x)
  })
  |> list.map(pair.second)
  |> Ok
}

pub fn set_row(
  display_buffer: DisplayBuffer,
  y_coord: Int,
  new_screen_row: List(Bool),
) -> Result(DisplayBuffer, DisplayBufferError) {
  use <- bool.guard(
    when: y_coord >= 32,
    return: Error(TriedToAccessFakeRow(y_coord)),
  )
  let DisplayBuffer(map) = display_buffer

  new_screen_row
  |> list.index_fold(from: map, with: fn(map, value, x_coord) {
    map |> dict.insert(for: #(x_coord, y_coord), insert: value)
  })
  |> DisplayBuffer
  |> Ok
}

pub fn clear(_: DisplayBuffer) -> Result(DisplayBuffer, DisplayBufferError) {
  new()
}
