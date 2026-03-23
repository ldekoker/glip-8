import chip8/cpu/display_buffer
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
