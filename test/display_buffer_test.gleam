import chip8/cpu/display_buffer
import gleam/bool
import gleam/int
import gleam/list
import gleam/result

pub fn display_buffer_test() {
  use new_display_buffer <- result.try(display_buffer.new())

  let assert Ok(falses) = new_display_buffer |> display_buffer.get_row(0)
  assert !list.any(falses, fn(bool) { bool })

  let new_row = int.range(0, 64, [], fn(pxs, idx) { [int.is_even(idx), ..pxs] })

  let assert Ok(new_display_buffer) =
    new_display_buffer |> display_buffer.set_row(0, new_row)

  let assert Ok(possibly_new_row) =
    new_display_buffer |> display_buffer.get_row(0)

  assert possibly_new_row == new_row
  Ok(Nil)
}

pub fn display_buffer_fake_row_test() {
  use new_display_buffer <- result.try(display_buffer.new())

  let assert Error(display_buffer.TriedToAccessFakeRow(-1)) =
    new_display_buffer |> display_buffer.get_row(-1)

  let assert Error(display_buffer.TriedToAccessFakeRow(32)) =
    new_display_buffer |> display_buffer.get_row(32)

  Ok(Nil)
}

pub fn display_buffer_blank_render_test() {
  let assert Ok(new_display_buffer) = display_buffer.new()
  let assert Ok(pixel_grid) = new_display_buffer |> display_buffer.render

  // All should be false
  assert pixel_grid
    |> list.map(fn(ls) { list.any(ls, fn(i) { i }) })
    |> list.any(fn(i) { i })
    |> bool.negate
}

pub fn display_buffer_single_line_test() {
  let assert Ok(#(new_display_buffer, _)) =
    display_buffer.new() |> result.try(display_buffer.draw(_, [0xFF], 0, 0))

  let assert Ok([first_row, ..]) = new_display_buffer |> display_buffer.render

  let first_eight_pixels = first_row |> list.take(8)

  assert first_eight_pixels |> list.all(fn(i) { i })
}

pub fn display_buffer_single_pixel_test() {
  let assert Ok(#(new_display_buffer, _)) =
    display_buffer.new() |> result.try(display_buffer.draw(_, [0x1], 1, 1))

  assert new_display_buffer |> get_pixel(1, 1)

  let assert Ok(grid) = new_display_buffer |> display_buffer.render

  assert {
      grid
      |> list.map(list.count(_, fn(i) { i }))
      |> list.fold(0, fn(a, b) { a + b })
    }
    == 1
}

pub fn display_buffer_square_test() {
  let assert Ok(#(new_display_buffer, _)) =
    display_buffer.new()
    |> result.try(display_buffer.draw(_, [0b111, 0b101, 0b111], 3, 3))

  assert new_display_buffer |> get_pixel(3, 3)
  assert new_display_buffer |> get_pixel(4, 3)
  assert new_display_buffer |> get_pixel(5, 3)

  assert new_display_buffer |> get_pixel(3, 4)

  assert new_display_buffer |> get_pixel(5, 4)

  assert new_display_buffer |> get_pixel(3, 5)
  assert new_display_buffer |> get_pixel(4, 5)
  assert new_display_buffer |> get_pixel(5, 5)
}

/// Sprites don't wrap around, only the initial coordinates.
pub fn display_buffer_square_edge_test() {
  let assert Ok(#(new_display_buffer, _)) =
    display_buffer.new()
    |> result.try(display_buffer.draw(_, [0b111, 0b101, 0b111], 63, 3))

  assert new_display_buffer |> get_pixel(63, 3)

  assert new_display_buffer |> get_pixel(63, 4)

  assert new_display_buffer |> get_pixel(63, 5)

  let assert Ok(grid) = new_display_buffer |> display_buffer.render

  assert {
      grid
      |> list.map(list.count(_, fn(i) { i }))
      |> list.fold(0, fn(a, b) { a + b })
    }
    == 3
}

pub fn display_buffer_square_wrap_around_test() {
  let assert Ok(#(new_display_buffer, _)) =
    display_buffer.new()
    |> result.try(display_buffer.draw(_, [0b111, 0b101, 0b111], 67, 67))

  assert new_display_buffer |> get_pixel(3, 3)
  assert new_display_buffer |> get_pixel(4, 3)
  assert new_display_buffer |> get_pixel(5, 3)

  assert new_display_buffer |> get_pixel(3, 4)

  assert new_display_buffer |> get_pixel(5, 4)

  assert new_display_buffer |> get_pixel(3, 5)
  assert new_display_buffer |> get_pixel(4, 5)
  assert new_display_buffer |> get_pixel(5, 5)
}

fn get_pixel(
  display_buffer: display_buffer.DisplayBuffer,
  x: Int,
  y: Int,
) -> Bool {
  let assert Ok(rows) = display_buffer |> display_buffer.render

  let assert Ok(row) = at(rows, index: y)

  let assert Ok(pixel) = at(row, index: x)

  pixel
}

fn at(list: List(a), index index: Int) -> Result(a, Nil) {
  at_loop(list, index, 0)
}

fn at_loop(list: List(a), index: Int, current_index: Int) -> Result(a, Nil) {
  case list, current_index {
    [item, ..], current_index if current_index == index -> Ok(item)
    [_, ..rest], current_index if current_index < index ->
      at_loop(rest, index, current_index + 1)
    _, _ -> Error(Nil)
  }
}
