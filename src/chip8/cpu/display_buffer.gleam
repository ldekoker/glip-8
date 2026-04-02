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
    create_sprite_buffer(sprite)
    |> handle_sprite_overflow(top_left_x, top_left_y)

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
  top_left_y: Int,
) -> List(List(Bool)) {
  sprite
  |> list.map(list.take(_, 64 - top_left_x))
  |> list.take(32 - top_left_y)
}

fn create_sprite_buffer(sprite: List(Int)) -> List(List(Bool)) {
  sprite
  |> list.map(decompose_binary)
  |> list.map(pad_to_eight)
}

fn pad_to_eight(list: List(Bool)) -> List(Bool) {
  let length = list |> list.length
  case length >= 8 {
    True -> list
    False -> list.repeat(False, 8 - length) |> list.append(list)
  }
}

fn decompose_binary(x: Int) {
  x |> do_decompose_binary |> list.reverse
}

fn do_decompose_binary(x: Int) -> List(Bool) {
  use <- bool.guard(x == 0, [False])
  use <- bool.guard(x == 1, [True])
  case x % 2 == 0 {
    True -> [
      False,
      ..do_decompose_binary(int.floor_divide(x, 2) |> result.unwrap(0))
    ]
    False -> [
      True,
      ..do_decompose_binary(int.floor_divide(x, 2) |> result.unwrap(0))
    ]
  }
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
