// import chip8/cpu/display_buffer
// import gleam/bool
// import gleam/int
// import gleam/list
// import gleam/result

// pub fn display_buffer_blank_render_test() {
//   let assert Ok(new_display_buffer) = display_buffer.new()
//   let pixel_grid = new_display_buffer |> to_pixel_grid

//   // All should be false
//   assert pixel_grid
//     |> list.map(fn(ls) { list.any(ls, fn(i) { i }) })
//     |> list.any(fn(i) { i })
//     |> bool.negate
// }

// pub fn display_buffer_single_line_test() {
//   let assert Ok(#(new_display_buffer, _)) =
//     display_buffer.new() |> result.try(display_buffer.draw(_, [0xFF], 0, 0))

//   let assert [first_row, ..] = new_display_buffer |> to_pixel_grid

//   let first_eight_pixels = first_row |> list.take(8)

//   // All of the first eight pixels should be set.
//   assert first_eight_pixels |> list.all(fn(i) { i })
// }

// pub fn display_buffer_single_pixel_test() {
//   let assert Ok(#(new_display_buffer, _)) =
//     display_buffer.new() |> result.try(display_buffer.draw(_, [0x80], 1, 1))

//   assert new_display_buffer |> to_pixel_grid |> is_set(1, 1)

//   let grid = new_display_buffer |> to_pixel_grid

//   assert {
//       grid
//       |> list.map(list.count(_, fn(i) { i }))
//       |> list.fold(0, fn(a, b) { a + b })
//     }
//     == 1
// }

// pub fn display_buffer_square_test() {
//   let assert Ok(#(new_display_buffer, _)) =
//     display_buffer.new()
//     |> result.try(display_buffer.draw(
//       _,
//       [0b11100000, 0b10100000, 0b11100000],
//       3,
//       3,
//     ))

//   let screen = new_display_buffer |> to_pixel_grid

//   assert screen |> is_set(3, 3)
//   assert screen |> is_set(4, 3)
//   assert screen |> is_set(5, 3)

//   assert screen |> is_set(3, 4)

//   assert screen |> is_set(5, 4)

//   assert screen |> is_set(3, 5)
//   assert screen |> is_set(4, 5)
//   assert screen |> is_set(5, 5)
// }

// /// Sprites don't wrap around, only the initial coordinates.
// pub fn display_buffer_square_edge_test() {
//   let assert Ok(#(new_display_buffer, _)) =
//     display_buffer.new()
//     |> result.try(display_buffer.draw(
//       _,
//       [0b11100000, 0b10100000, 0b11100000],
//       63,
//       3,
//     ))

//   let screen = new_display_buffer |> to_pixel_grid

//   assert screen |> is_set(63, 3)

//   assert screen |> is_set(63, 4)

//   assert screen |> is_set(63, 5)

//   let assert Ok(grid) = new_display_buffer |> display_buffer.render

//   assert {
//       grid
//       |> list.map(list.count(_, fn(i) { i }))
//       |> list.fold(0, fn(a, b) { a + b })
//     }
//     == 3
// }

// pub fn display_buffer_square_wrap_around_test() {
//   let assert Ok(#(new_display_buffer, _)) =
//     display_buffer.new()
//     |> result.try(display_buffer.draw(
//       _,
//       [0b11100000, 0b10100000, 0b11100000],
//       67,
//       67,
//     ))

//   let screen = new_display_buffer |> to_pixel_grid

//   assert screen |> is_set(3, 3)
//   assert screen |> is_set(4, 3)
//   assert screen |> is_set(5, 3)

//   assert screen |> is_set(3, 4)

//   assert screen |> is_set(5, 4)

//   assert screen |> is_set(3, 5)
//   assert screen |> is_set(4, 5)
//   assert screen |> is_set(5, 5)
// }

// fn to_pixel_grid(display_buffer: display_buffer.DisplayBuffer) -> VirtualScreen {
//   let assert Ok(screen) = display_buffer |> display_buffer.render
//   screen
// }

// type VirtualScreen =
//   List(List(Bool))

// fn is_set(screen: VirtualScreen, target_x: Int, target_y: Int) -> Bool {
//   use is_set, row, y <- list.index_fold(screen, True)
//   use is_set, pixel, x <- list.index_fold(row, is_set)

//   case #(x, y) == #(target_x, target_y) {
//     True -> pixel
//     False -> is_set
//   }
// }
