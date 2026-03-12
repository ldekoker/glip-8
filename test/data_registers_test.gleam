import gleam/int
import gleam/result
import internal/cpu/data_registers

pub fn data_registers_initialise_test() {
  let d = data_registers.new()

  assert int.range(from: 0, to: 15, with: True, run: fn(so_far, idx) {
    so_far && data_registers.get_register(d, idx) == Ok(0)
  })
}

pub fn data_registers_set_test() {
  use d <- result.try(set_data_registers(data_registers.new()))

  assert int.range(from: 0, to: 15, with: True, run: fn(so_far, idx) {
    so_far && data_registers.get_register(d, idx) == Ok(idx)
  })

  Ok(Nil)
}

fn set_data_registers(d: data_registers.DataRegisters) {
  d
  |> data_registers.set_register(1, 1)
  |> result.try(data_registers.set_register(_, 2, 2))
  |> result.try(data_registers.set_register(_, 3, 3))
  |> result.try(data_registers.set_register(_, 4, 4))
  |> result.try(data_registers.set_register(_, 5, 5))
  |> result.try(data_registers.set_register(_, 6, 6))
  |> result.try(data_registers.set_register(_, 7, 7))
  |> result.try(data_registers.set_register(_, 8, 8))
  |> result.try(data_registers.set_register(_, 9, 9))
  |> result.try(data_registers.set_register(_, 10, 10))
  |> result.try(data_registers.set_register(_, 11, 11))
  |> result.try(data_registers.set_register(_, 12, 12))
  |> result.try(data_registers.set_register(_, 13, 13))
  |> result.try(data_registers.set_register(_, 14, 14))
  |> result.try(data_registers.set_register(_, 15, 15))
}
