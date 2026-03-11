import gleam/bool
import gleam/list
import gleam/option.{type Option, None, Some}
import internal/cpu/data_registers

pub fn data_registers_initialise_test() {
  let data_registers = data_registers.new()
  let range = list.range(0, 15)
  assert list.all(range, fn(idx) {
    data_registers |> data_registers.get_register(idx) == Some(0)
  })
}
