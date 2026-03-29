import chip8/cpu/memory
import gleam/result

pub fn memory_test() {
  let memory = memory.new()

  let assert Ok(0) = memory |> memory.get_value_at(0)
  let assert Ok(0) = memory |> memory.get_value_at(900)
  let assert Ok(0) = memory |> memory.get_value_at(4095)

  let assert Ok(new_memory) =
    memory
    |> memory.set_value_at(0, 93)
    |> result.try(memory.set_value_at(_, 900, 21))
    |> result.try(memory.set_value_at(_, 4095, 255))

  let assert Ok(93) = new_memory |> memory.get_value_at(0)
  let assert Ok(21) = new_memory |> memory.get_value_at(900)
  let assert Ok(255) = new_memory |> memory.get_value_at(4095)
}

pub fn memory_bad_access_test() {
  let memory = memory.new()

  let assert Error(memory.TriedToAccessFakeAddress(-1)) =
    memory |> memory.get_value_at(-1)
  let assert Error(memory.TriedToAccessFakeAddress(4096)) =
    memory |> memory.get_value_at(4096)

  let assert Error(memory.TriedToAccessFakeAddress(-1)) =
    memory |> memory.set_value_at(-1, 1)
  let assert Error(memory.TriedToAccessFakeAddress(4096)) =
    memory |> memory.set_value_at(4096, 1)
}

pub fn memory_flow_test() {
  let memory = memory.new()

  let assert Error(memory.ValueOverflow(256)) =
    memory |> memory.set_value_at(0, 256)

  let assert Error(memory.ValueUnderflow(-1)) =
    memory |> memory.set_value_at(0, -1)
}
