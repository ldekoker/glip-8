import gleam/result
import internal/cpu/address_register
import internal/cpu/byte_memory
import internal/cpu/data_registers
import internal/cpu/display_buffer
import internal/cpu/timer as tim
import internal/instructions as i

pub opaque type CPU {
  CPU(
    memory: byte_memory.ByteMemory,
    data_registers: byte_memory.ByteMemory,
    address_register: address_register.AddressRegister,
    delay_timer: tim.Timer,
    sound_timer: tim.Timer,
    display_buffer: display_buffer.DisplayBuffer,
    key_pad: data_registers.DataRegisters,
  )
}

pub opaque type CPUError {
  InstructionError(instruction: i.Instruction)
}

pub fn new() -> CPU {
  CPU(
    memory: byte_memory.new(4096),
    data_registers: byte_memory.new(16),
    address_register: address_register.new(),
    delay_timer: tim.new(),
    sound_timer: tim.new(),
    display_buffer: display_buffer.new(),
    key_pad: data_registers.new(),
  )
}

pub fn run(cpu: CPU) -> Result(CPU, Nil) {
  todo
  let fetch_and_decode_instruction = fn(c) {
    use instruction <- result.try(
      c
      |> fetch_instruction
      |> result.try(i.decode_instruction),
    )

    cpu |> fetch_and_decode_instruction |> apply_instruction
  }

  use instruction <- result.try(fetch_and_decode_instruction(cpu))

  Ok(cpu |> apply_instruction(instruction))
}

fn fetch_instruction(cpu: CPU) -> Result(Int, Nil) {
  use instruction <- result.try(
    cpu.address_register
    |> address_register.get_value()
    |> result.try(fn(adr) {
      byte_memory.get_value_at_address(cpu.memory, adr)
      |> result.replace_error(Nil)
    }),
  )

  Ok(instruction)
}

pub fn apply_instruction(cpu: CPU, instruction: i.Instruction) -> CPU {
  todo
}
