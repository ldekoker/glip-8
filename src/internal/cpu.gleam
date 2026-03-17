import gleam/int
import gleam/list
import gleam/result
import internal/cpu/fixed_length_bit_array
import internal/cpu/stack
import internal/cpu/timer as tim
import internal/instructions as i

pub opaque type CPU {
  CPU(
    memory: fixed_length_bit_array.FixedLengthBitArray,
    variable_registers: fixed_length_bit_array.FixedLengthBitArray,
    address_register: Int,
    delay_timer: tim.Timer,
    sound_timer: tim.Timer,
    display_buffer: fixed_length_bit_array.FixedLengthBitArray,
    keypad: fixed_length_bit_array.FixedLengthBitArray,
    stack: stack.Stack(Int),
    pc: Int,
  )
}

pub type CPUError {
  DecodeError(opcode: Int)
  FailedToInitialise(component: String)
  FailedToFetch(address: Int)
}

pub fn new() -> Result(CPU, CPUError) {
  use memory <- result.try(
    fixed_length_bit_array.new(length: 4096, bits: 8)
    |> result.replace_error(FailedToInitialise("Memory")),
  )
  use variable_registers <- result.try(
    fixed_length_bit_array.new(length: 16, bits: 8)
    |> result.replace_error(FailedToInitialise("Data Registers")),
  )
  use display_buffer <- result.try(
    fixed_length_bit_array.new(length: 32, bits: 64)
    |> result.replace_error(FailedToInitialise("Display Buffer")),
  )
  use keypad <- result.try(
    fixed_length_bit_array.new(length: 16, bits: 1)
    |> result.replace_error(FailedToInitialise("Keypad")),
  )

  Ok(CPU(
    memory:,
    variable_registers:,
    address_register: 0,
    delay_timer: tim.new(),
    sound_timer: tim.new(),
    display_buffer:,
    keypad:,
    stack: stack.new(),
    pc: 0,
  ))
}

pub fn run(cpu: CPU) -> Result(CPU, CPUError) {
  let decode_instruction = fn(opcode) {
    i.decode_instruction(opcode)
    |> result.map_error(fn(err) {
      case err {
        i.InvalidOpcode(opcode:) -> DecodeError(opcode)
      }
    })
  }

  // Increment PC by 2, figure out when

  Ok(cpu)
  |> result.try(fetch_instruction)
  |> result.try(decode_instruction)
  |> result.try(apply_instruction(cpu, _))
}

fn increment_pc(cpu: CPU) -> CPU {
  CPU(..cpu, pc: cpu.pc + 2)
}

fn fetch_instruction(cpu: CPU) -> Result(Int, CPUError) {
  let get_nib1 =
    fixed_length_bit_array.get_value_at_address(
      cpu.memory,
      cpu.address_register,
    )
    |> result.replace_error(FailedToFetch(cpu.address_register))

  let get_nib2 =
    fixed_length_bit_array.get_value_at_address(
      cpu.memory,
      cpu.address_register + 1,
    )
    |> result.replace_error(FailedToFetch(cpu.address_register + 1))

  use nib1 <- result.try(get_nib1)
  use nib2 <- result.try(get_nib2)
  Ok(int.bitwise_shift_left(nib1, 8) + nib2)
}

pub fn apply_instruction(
  cpu: CPU,
  instruction: i.Instruction,
) -> Result(CPU, CPUError) {
  todo
}

/// Transforms a DisplayBuffer into a nested list of Boolean values.
/// Always outputs a list of 32 lists of 64 booleans.
pub fn to_display(cpu: CPU) -> List(List(Bool)) {
  let display_buffer = cpu.display_buffer
  let bits = display_buffer |> fixed_length_bit_array.get_bit_array
  bits |> bit_array_to_list_of_bits |> list.sized_chunk(into: 64)
}

/// Recursively transform a BitArray into a list of Booleans.
/// TCO-optimised.
fn bit_array_to_list_of_bits(bits: BitArray) -> List(Bool) {
  bit_array_to_list_of_bits_loop(bits, [])
}

fn bit_array_to_list_of_bits_loop(
  bits: BitArray,
  bools: List(Bool),
) -> List(Bool) {
  case bits {
    <<first_bit:1, rest:bits>> -> {
      let new_bools = [first_bit == 1, ..bools]
      bit_array_to_list_of_bits_loop(rest, new_bools)
    }
    _ -> list.reverse(bools)
  }
}
