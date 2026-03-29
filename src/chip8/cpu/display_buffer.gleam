import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string

// A 64x32 display buffer.
pub opaque type DisplayBuffer {
  DisplayBuffer(dict.Dict(#(Int, Int), Bool))
}

pub type DisplayBufferError {
  TriedToAccessFakeRow(Int)
  IncorrectRowLength(Int)
  CouldNotAccessSpriteRow
  CouldNotGetPixel(#(Int, Int))
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
  use <- bool.guard(
    when: row < 0 || row >= 32,
    return: Error(TriedToAccessFakeRow(row)),
  )
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
    when: y_coord < 0 || y_coord >= 32,
    return: Error(TriedToAccessFakeRow(y_coord)),
  )
  let row_length = new_screen_row |> list.length
  use <- bool.guard(
    when: row_length != 64,
    return: Error(IncorrectRowLength(row_length)),
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

fn get_pixel(display_buffer: DisplayBuffer, x: Int, y: Int) {
  let DisplayBuffer(map) = display_buffer
  map
  |> dict.get(#(x, y))
  |> result.map_error(fn(error) {
    case error {
      Nil -> CouldNotGetPixel(#(x, y))
    }
  })
}

pub fn draw(
  display_buffer: DisplayBuffer,
  sprite: List(Int),
  starting_x_coord: Int,
  starting_y_coord: Int,
) -> Result(#(DisplayBuffer, Bool), DisplayBufferError) {
  let top_left_x = starting_x_coord % 64
  let top_left_y = starting_y_coord % 32

  let sprite_rows =
    create_sprite_buffer(sprite) |> handle_sprite_overflow(top_left_x)

  use pair, sprite_row, y_offset <- list.index_fold(
    sprite_rows,
    Ok(#(display_buffer, False)),
  )
  use #(display_buffer, has_flipped) <- result.try(pair)

  use pair, sprite_pixel, x_offset <- list.index_fold(
    sprite_row,
    Ok(#(display_buffer, has_flipped)),
  )
  use #(display_buffer, has_flipped) <- result.try(pair)

  let y_coord = top_left_y + y_offset
  let x_coord = top_left_x + x_offset

  use current_pixel <- result.try(display_buffer |> get_pixel(x_coord, y_coord))

  let #(new_pixel, has_flipped) = case current_pixel, sprite_pixel {
    True, True -> #(False, True)
    False, False -> #(False, has_flipped)
    True, False | False, True -> #(True, has_flipped)
  }

  Ok(#(display_buffer |> set_pixel(x_coord, y_coord, new_pixel), has_flipped))
}

fn handle_sprite_overflow(
  sprite: List(List(Bool)),
  top_left_x: Int,
) -> List(List(Bool)) {
  sprite |> list.map(list.take(_, 64 - top_left_x))
}

fn create_sprite_buffer(sprite: List(Int)) -> List(List(Bool)) {
  let sprite_rows =
    sprite
    |> list.map(fn(num) {
      num
      |> int.to_base2
      |> string.to_graphemes
      |> list.map(fn(char) {
        case char {
          "0" -> False
          "1" -> True
          _ -> panic
        }
      })
    })
  sprite_rows
}

fn set_pixel(
  display_buffer: DisplayBuffer,
  x: Int,
  y: Int,
  new_pixel: Bool,
) -> DisplayBuffer {
  let DisplayBuffer(map) = display_buffer

  map |> dict.insert(#(x, y), new_pixel) |> DisplayBuffer
}

pub fn render(display_buffer: DisplayBuffer) -> Result(List(List(Bool)), Nil) {
  let DisplayBuffer(map) = display_buffer

  {
    use rows, y_coord <- int.range(0, 32, [] |> Ok)

    use new_row <- result.try(
      int.range(0, 64, [] |> Ok, fn(current_row, x_coord) {
        use current_pixel <- result.try(map |> dict.get(#(x_coord, y_coord)))
        use current_row <- result.try(current_row)

        [current_pixel, ..current_row] |> Ok
      }),
    )
    use rows <- result.try(rows)

    [new_row, ..rows] |> Ok
  }
}
