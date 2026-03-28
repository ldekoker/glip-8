import chip8/cpu/address_register.{type AddressRegister}
import chip8/cpu/display_buffer.{type DisplayBuffer}
import chip8/cpu/keypad.{type KeyPad}
import chip8/cpu/memory.{type Memory}
import chip8/cpu/program_counter.{type ProgramCounter}
import chip8/cpu/stack.{type Stack}
import chip8/cpu/timer.{type Timer}
import chip8/cpu/variable_registers.{type VariableRegisters}
import chip8/font_file.{FontFile}
import chip8/instructions as i
import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub opaque type CPU {
  CPU(
    memory: Memory,
    variable_registers: VariableRegisters,
    address_register: AddressRegister,
    delay_timer: Timer,
    sound_timer: Timer,
    display_buffer: DisplayBuffer,
    keypad: KeyPad,
    stack: Stack,
    pc: ProgramCounter,
    behaviour_flags: CPUBehaviourFlags,
  )
}

pub opaque type CPUBehaviourFlags {
  CPUBehaviourFlags(
    bit_shift_flag: Bool,
    bnnn_flag: Bool,
    fx1e_flag: Bool,
    mem_flag: Bool,
  )
}

pub type CPUConfig {
  Cosmac
  Modern
}

fn config_to_flags(config: CPUConfig) -> CPUBehaviourFlags {
  case config {
    Cosmac ->
      CPUBehaviourFlags(
        bit_shift_flag: False,
        bnnn_flag: False,
        fx1e_flag: False,
        mem_flag: False,
      )
    Modern ->
      CPUBehaviourFlags(
        bit_shift_flag: False,
        bnnn_flag: False,
        fx1e_flag: False,
        mem_flag: True,
      )
  }
}

pub type CPUError {
  FailedToInitialiseMemory
  FailedToFetchMemory(address: Int)
  FailedToSetMemory(address: Int)
  FailedToInitialiseVariableRegisters
  FailedToSetV(Int)
  FailedToGetFromV(Int)
  IValueOverflow(Int)
  TriedToAccessFakeDisplayRow(Int)
  TimerError
  FailedToInitialiseKeypad
  TriedToAccessFakeKey(Int)
  PCValueOverflow(Int)
  FailedToInitialiseStack
  PushToFullStack
  PopFromEmptyStack
  StackValueOverflow(Int)
  StackError
  DecodeError(Int)
  AttemptToDecimaliseNegativeNumber
  NotInFont(char: Int)
  TimerOverflow(Int)
  TriedToAccessFakeDisplayColumn(Int)
  IValueUnderflow(Int)
  StackValueUnderflow(Int)
  DisplayReceivedIncorrectRowLength(Int)
  TriedToAccessFakeMemoryAddress(address: Int)
  MemoryOverflow(value: Int)
  MemoryUnderflow(value: Int)
  InternalDisplayBufferError
}

pub fn new(config: CPUConfig) -> Result(CPU, CPUError) {
  use memory <- result.try(memory.new() |> from_memory_error)
  use variable_registers <- result.try(
    variable_registers.new() |> from_variable_registers_error,
  )
  use address_register <- result.try(
    address_register.new(0) |> from_address_registers_error,
  )
  use delay_timer <- result.try(timer.new() |> from_timer_error)
  use sound_timer <- result.try(timer.new() |> from_timer_error)
  use display_buffer <- result.try(
    display_buffer.new() |> from_display_buffer_error,
  )
  use keypad <- result.try(keypad.new() |> from_keypad_error)
  use pc <- result.try(
    program_counter.new()
    |> result.try(program_counter.set_value(_, 0x200))
    |> from_program_counter_error,
  )
  use stack <- result.try(stack.new() |> from_stack_error)

  CPU(
    memory:,
    variable_registers:,
    address_register:,
    delay_timer:,
    sound_timer:,
    display_buffer:,
    keypad:,
    stack:,
    pc:,
    behaviour_flags: config_to_flags(config),
  )
  |> load_font(font_file.base_font)
}

fn from_memory_error(
  result: Result(a, memory.MemoryError),
) -> Result(a, CPUError) {
  use error <- result.map_error(result)
  case error {
    memory.FailedToInitialise -> FailedToInitialiseMemory
    memory.TriedToAccessFakeAddress(address:) ->
      TriedToAccessFakeMemoryAddress(address:)
    memory.ValueOverflow(value:) -> MemoryOverflow(value:)
    memory.ValueUnderflow(value:) -> MemoryUnderflow(value:)
  }
}

fn from_variable_registers_error(
  result: Result(a, variable_registers.VariableRegistersError),
) -> Result(a, CPUError) {
  use error <- result.map_error(result)
  case error {
    variable_registers.FailedToInitialise -> FailedToInitialiseVariableRegisters
    variable_registers.FailedToSetV(x) -> FailedToSetV(x)
    variable_registers.FailedToGetFromV(x) -> FailedToGetFromV(x)
  }
}

fn from_address_registers_error(
  result: Result(a, address_register.AddressRegisterError),
) -> Result(a, CPUError) {
  use error <- result.map_error(result)
  case error {
    address_register.ValueOverflow(value) -> IValueOverflow(value)
    address_register.ValueUnderflow(value) -> IValueUnderflow(value)
  }
}

fn from_display_buffer_error(
  result: Result(a, display_buffer.DisplayBufferError),
) -> Result(a, CPUError) {
  use error <- result.map_error(result)
  case error {
    display_buffer.TriedToAccessFakeRow(row) -> TriedToAccessFakeDisplayRow(row)
    display_buffer.IncorrectRowLength(row_length) ->
      DisplayReceivedIncorrectRowLength(row_length)
    display_buffer.CouldNotAccessSpriteRow -> InternalDisplayBufferError
    display_buffer.CouldNotGetPixel(_) -> InternalDisplayBufferError
  }
}

fn from_timer_error(result: Result(a, timer.TimerError)) -> Result(a, CPUError) {
  use error <- result.map_error(result)
  case error {
    timer.ValueOverflow(value) -> TimerOverflow(value)
  }
}

fn from_keypad_error(
  result: Result(a, keypad.KeyPadError),
) -> Result(a, CPUError) {
  use error <- result.map_error(result)
  case error {
    keypad.FailedToInitialise -> FailedToInitialiseKeypad
    keypad.TriedToAccessFakeKey(key) -> TriedToAccessFakeKey(key)
  }
}

fn from_program_counter_error(
  result: Result(a, program_counter.ProgramCounterError),
) -> Result(a, CPUError) {
  use error <- result.map_error(result)
  case error {
    program_counter.ValueOverflow(value) -> PCValueOverflow(value)
  }
}

fn from_stack_error(result: Result(a, stack.StackError)) -> Result(a, CPUError) {
  use error <- result.map_error(result)
  case error {
    stack.FailedToInitialise -> FailedToInitialiseStack
    stack.PushToFullStack -> PushToFullStack
    stack.ValueOverflow(value) -> StackValueOverflow(value)
    stack.ArrayError(_) -> StackError
    stack.PopFromEmptyStack -> PopFromEmptyStack
    stack.ValueUnderflow(value) -> StackValueUnderflow(value)
  }
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

  Ok(cpu)
  |> result.try(fetch_instruction)
  |> result.try(decode_instruction)
  |> result.try(fn(instruction) {
    use new_cpu <- result.try(cpu |> increment_pc(2))
    apply_instruction(new_cpu, instruction)
  })
}

fn increment_pc(cpu: CPU, by value: Int) -> Result(CPU, CPUError) {
  use new_pc <- result.try(
    cpu.pc |> program_counter.increment_by(value) |> from_program_counter_error,
  )
  CPU(..cpu, pc: new_pc) |> Ok
}

fn get_memory_at(cpu: CPU, address address: Int) -> Result(Int, CPUError) {
  cpu.memory
  |> memory.get_value_at(address)
  |> from_memory_error
}

fn set_memory_at(
  cpu: CPU,
  address address: Int,
  to value: Int,
) -> Result(CPU, CPUError) {
  use new_memory <- result.try({
    cpu.memory
    |> memory.set_value_at(address, value)
    |> from_memory_error
  })

  Ok(CPU(..cpu, memory: new_memory))
}

fn fetch_instruction(cpu: CPU) -> Result(Int, CPUError) {
  let i = cpu.pc |> program_counter.get_value
  use byte1 <- result.try(cpu |> get_memory_at(i))
  use byte2 <- result.try(
    cpu
    |> get_memory_at(i + 1),
  )

  // {byte1}{byte2}, e.g {0xA2}{0x03} = 0x{A203}
  Ok(byte1 |> int.bitwise_shift_left(8) |> int.bitwise_or(byte2))
}

pub fn apply_instruction(
  cpu: CPU,
  instruction: i.Instruction,
) -> Result(CPU, CPUError) {
  case instruction {
    i.ExecuteMachineLanguageSubroutineAtAddress(_) -> Ok(cpu)

    i.ClearScreen -> cpu |> clear_screen

    i.Return -> cpu |> return

    i.JumpToAddress(nnn:) -> cpu |> set_pc(nnn)

    i.ExecuteSubroutineAtAddress(nnn:) -> cpu |> call(nnn)

    i.SkipNextIfVXEqualsNN(vx:, nn:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      cpu |> skip_if(val_at_vx == nn)
    }
    i.SkipNextIfVXNotEqualsNN(vx:, nn:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      cpu |> skip_if(val_at_vx != nn)
    }
    i.SkipNextIfVXEqualsVY(vx:, vy:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      cpu |> skip_if(val_at_vx == val_at_vy)
    }
    i.StoreNNinVX(nn:, vx:) -> {
      cpu |> set_value_at_v(vx, nn)
    }
    i.AddNNtoVX(nn:, vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      cpu |> set_value_at_v(vx, val_at_vx + nn)
    }
    i.StoreVYinVX(vy:, vx:) -> {
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      cpu |> set_value_at_v(vx, val_at_vy)
    }
    i.SetVXtoVXorVY(vx:, vy:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      cpu |> set_value_at_v(vx, int.bitwise_or(val_at_vx, val_at_vy))
    }
    i.SetVXtoVXandVY(vx:, vy:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      cpu |> set_value_at_v(vx, int.bitwise_and(val_at_vx, val_at_vy))
    }
    i.SetVXtoVXxorVY(vx:, vy:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      cpu |> set_value_at_v(vx, int.bitwise_exclusive_or(val_at_vx, val_at_vy))
    }
    i.AddVYtoVXCarry(vx:, vy:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      let sum = val_at_vx + val_at_vy
      let truncated_sum = sum % 256
      let flag_value = case truncated_sum != sum {
        True -> 1
        False -> 0
      }

      cpu
      |> set_value_at_v(vx, truncated_sum)
      |> result.try(set_value_at_v(_, 0xF, flag_value))
    }
    i.SubtractVYfromVXBorrow(vx:, vy:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      let result = val_at_vx - val_at_vy
      let flag_value = case result >= 0 {
        True -> 1
        False -> 0
      }

      cpu
      |> set_value_at_v(vx, result)
      |> result.try(set_value_at_v(_, 0xF, flag_value))
    }
    i.StoreVYinVXBitShiftedRight(vx:, vy:) -> {
      // Note: Configurable behaviour desired. Using COSMAC VIP behaviour.
      use value <- result.try(case cpu.behaviour_flags.bit_shift_flag {
        False -> cpu |> get_value_of_v(vy)
        True -> cpu |> get_value_of_v(vx)
      })

      let least_significant_bit = value |> int.bitwise_and(0b00000001)

      cpu
      |> set_value_at_v(vx, value |> int.bitwise_shift_right(1))
      |> result.try(set_value_at_v(_, 0xF, least_significant_bit))
    }
    i.SetVXtoVYminusVXBorrow(vx:, vy:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      let result = val_at_vy - val_at_vx
      let flag_value = case result >= 0 {
        True -> 1
        False -> 0
      }

      cpu
      |> set_value_at_v(vx, result)
      |> result.try(set_value_at_v(_, 0xF, flag_value))
    }
    i.StoreVYinVXBitShiftedLeft(vx:, vy:) -> {
      // Note: Configurable behaviour desired. Using COSMAC VIP behaviour.
      use value <- result.try(case cpu.behaviour_flags.bit_shift_flag {
        False -> cpu |> get_value_of_v(vy)
        True -> cpu |> get_value_of_v(vx)
      })

      let most_significant_bit = value |> int.bitwise_and(0b10000000)

      cpu
      |> set_value_at_v(vx, value |> int.bitwise_shift_left(1))
      |> result.try(set_value_at_v(_, 0xF, most_significant_bit))
    }
    i.SkipNextIfVXNotEqualsVY(vx:, vy:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      cpu |> skip_if(val_at_vx != val_at_vy)
    }
    i.StoreAddressInI(nnn:) -> {
      cpu |> set_address_register(nnn)
    }
    i.JumpToNNNPlusV0(vx:, nn:, nnn:) -> {
      use val_at_v0 <- result.try(cpu |> get_value_of_v(0x0))

      let pc_val = case cpu.behaviour_flags.bnnn_flag {
        False -> nnn + val_at_v0
        True -> { vx |> int.bitwise_shift_left(8) } + nn + val_at_v0
      }

      cpu |> set_pc(pc_val)
    }
    i.SetVXToRand(vx:, mask:) -> {
      // IMPURE IMPURE IMPURE
      let rand = int.random(255) |> int.bitwise_and(mask)

      cpu |> set_value_at_v(vx, rand)
    }
    i.Draw(vx:, vy:, n:) -> {
      cpu |> draw(vx, vy, n)
    }
    i.SkipNextIfKeyPressed(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use key_pressed <- result.try(cpu |> is_key_pressed(val_at_vx))

      cpu |> skip_if(key_pressed)
    }
    i.SkipNextIfKeyNotPressed(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use key_pressed <- result.try(cpu |> is_key_pressed(val_at_vx))

      cpu |> skip_if(!key_pressed)
    }
    i.StoreDelayTimerInVX(vx:) -> {
      let delay_timer_value = cpu.delay_timer |> timer.get_value

      cpu |> set_value_at_v(vx, delay_timer_value)
    }
    i.OnKeypressStoreInVX(vx:) -> {
      case get_pressed_key(cpu) {
        Ok(key) -> {
          cpu |> set_value_at_v(vx, key)
        }
        _ -> {
          cpu |> increment_pc(-2)
        }
      }
    }
    i.SetDelayTimerToVX(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      cpu |> set_delay_timer(val_at_vx)
    }
    i.SetSoundTimerToVX(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      cpu |> set_sound_timer(val_at_vx)
    }
    i.AddVXtoI(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      let i_plus_vx = { cpu |> get_address_register_value } + val_at_vx

      case cpu.behaviour_flags.fx1e_flag, i_plus_vx > 0xFFF {
        True, True -> {
          cpu
          |> set_value_at_v(0xF, 1)
          |> result.try(set_address_register(_, i_plus_vx))
        }
        _, _ -> cpu |> set_address_register(i_plus_vx)
      }
    }
    i.SetItoFontAddress(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      use font_address <- result.try(
        val_at_vx |> int.bitwise_and(0b1111) |> get_font_address,
      )

      cpu |> set_address_register(font_address)
    }
    i.StoreDecimalisedVXInIs(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use #(hundreds, tens, ones) <- result.try(
        split(val_at_vx)
        |> result.replace_error(AttemptToDecimaliseNegativeNumber),
      )

      let i = cpu |> get_address_register_value

      Ok(cpu)
      |> result.try(set_memory_at(_, i, hundreds))
      |> result.try(set_memory_at(_, i + 1, tens))
      |> result.try(set_memory_at(_, i + 2, ones))
    }
    i.StoreMemory(vx:) -> {
      int.range(from: 0, to: vx + 1, with: Ok(cpu), run: fn(maybe_cpu, index) {
        use cpu <- result.try(maybe_cpu)

        // Get v_index register value
        use val_at_v_index: Int <- result.try(cpu |> get_value_of_v(index))

        let i = cpu |> get_address_register_value

        case cpu.behaviour_flags.mem_flag {
          False -> {
            // Set memory value at I
            // Increment address register
            cpu
            |> set_memory_at(i, val_at_v_index)
            |> result.try(set_address_register(_, i + 1))
          }
          True -> {
            // Set memory value at I
            cpu
            |> set_memory_at(i + index, val_at_v_index)
          }
        }
      })
    }
    i.LoadMemory(vx:) -> {
      int.range(from: 0, to: vx + 1, with: Ok(cpu), run: fn(maybe_cpu, index) {
        use cpu <- result.try(maybe_cpu)
        let i = cpu |> get_address_register_value

        case cpu.behaviour_flags.mem_flag {
          False -> {
            // Get memory value at I
            use val_at_address <- result.try(cpu |> get_memory_at(address: i))

            // Set v_index register
            cpu
            |> set_value_at_v(index, val_at_address)
            |> result.try(set_address_register(_, i + 1))
          }

          True -> {
            // Get memory value at I
            use val_at_address <- result.try(
              cpu |> get_memory_at(address: i + index),
            )

            cpu |> set_value_at_v(index, val_at_address)
          }
        }
      })
    }
  }
}

fn get_address_register_value(cpu: CPU) -> Int {
  cpu.address_register |> address_register.get_value
}

fn set_address_register(cpu: CPU, new_value: Int) -> Result(CPU, CPUError) {
  use new_address_register <- result.try(
    cpu.address_register
    |> address_register.set_value(new_value)
    |> from_address_registers_error,
  )

  Ok(CPU(..cpu, address_register: new_address_register))
}

fn set_delay_timer(cpu: CPU, new_value: Int) -> Result(CPU, CPUError) {
  use new_timer <- result.try(
    cpu.delay_timer |> timer.set_value(new_value) |> from_timer_error,
  )

  Ok(CPU(..cpu, delay_timer: new_timer))
}

fn set_sound_timer(cpu: CPU, new_value: Int) -> Result(CPU, CPUError) {
  use new_timer <- result.try(
    cpu.sound_timer |> timer.set_value(new_value) |> from_timer_error,
  )

  Ok(CPU(..cpu, sound_timer: new_timer))
}

/// Loads font data into CPU memory.
/// Each character is stored at character value * 5
/// e.g 3 is at 15.
fn load_font(cpu: CPU, font_file: font_file.FontFile) -> Result(CPU, CPUError) {
  let FontFile(
    zero:,
    one:,
    two:,
    three:,
    four:,
    five:,
    six:,
    seven:,
    eight:,
    nine:,
    a:,
    b:,
    c:,
    d:,
    e:,
    f:,
  ) = font_file
  use cpu, #(char, char_value) <- list.try_fold(
    [
      #(zero, 0),
      #(one, 1),
      #(two, 2),
      #(three, 3),
      #(four, 4),
      #(five, 5),
      #(six, 6),
      #(seven, 7),
      #(eight, 8),
      #(nine, 9),
      #(a, 0xA),
      #(b, 0xB),
      #(c, 0xC),
      #(d, 0xD),
      #(e, 0xE),
      #(f, 0xF),
    ],
    cpu,
  )

  let #(line1, line2, line3, line4, line5) = char
  use cpu, #(line, line_index) <- list.try_fold(
    [#(line1, 0), #(line2, 1), #(line3, 2), #(line4, 3), #(line5, 4)],
    cpu,
  )

  let index = char_value * 5 + line_index

  cpu |> set_memory_at(index, line)
}

/// Returns the location of the given character, if it is in the font.
/// Only takes 4-bit values, i.e 0 <= font_value <= 0b1111
fn get_font_address(font_value: Int) -> Result(Int, CPUError) {
  use <- bool.guard(
    when: !{ 0 <= font_value && font_value <= 0xF },
    return: Error(NotInFont(char: font_value)),
  )
  Ok(font_value * 5)
}

/// Gets the first pressed key in numeric order.
fn get_pressed_key(cpu: CPU) -> Result(Int, Nil) {
  cpu.keypad |> keypad.get_pressed
}

fn is_key_pressed(cpu: CPU, key: Int) -> Result(Bool, CPUError) {
  cpu.keypad |> keypad.is_pressed(key) |> from_keypad_error
}

// Skips the next instruction if the boolean is True.
fn skip_if(cpu: CPU, bool: Bool) -> Result(CPU, CPUError) {
  case bool {
    True -> cpu |> increment_pc(2)
    False -> cpu |> Ok
  }
}

fn draw(cpu: CPU, vx: Int, vy: Int, n: Int) -> Result(CPU, CPUError) {
  let i = cpu |> get_address_register_value
  use starting_x_coord <- result.try(
    cpu |> get_value_of_v(vx) |> result.map(fn(x) { x % 64 }),
  )
  use starting_y_coord <- result.try(
    cpu |> get_value_of_v(vy) |> result.map(fn(y) { y % 32 }),
  )

  let ending_y_coord = int.min(starting_y_coord + n, 32)
  // exclusive
  let range = starting_y_coord - ending_y_coord

  use sprite <- result.try(cpu |> get_sprite(i, range))

  use #(new_display_buffer, bit_flipped_off) <- result.try(
    cpu.display_buffer
    |> display_buffer.draw(sprite, starting_x_coord, starting_y_coord)
    |> from_display_buffer_error,
  )

  CPU(..cpu, display_buffer: new_display_buffer)
  |> set_value_at_v(0xF, case bit_flipped_off {
    True -> 1
    False -> 0
  })
}

fn get_sprite(cpu: CPU, i: Int, range: Int) -> Result(List(Int), CPUError) {
  int.range(0, range, [] |> Ok, fn(rows, y_offset) {
    use value_at_location <- result.try(cpu |> get_memory_at(i + y_offset))
    use rows <- result.try(rows)
    [value_at_location, ..rows] |> Ok
  })
  |> result.map(list.reverse)
}

/// Sets Program Counter to NNN and saves current PC value to call stack.
fn call(cpu: CPU, nnn: Int) -> Result(CPU, CPUError) {
  cpu
  |> set_pc(nnn)
  |> result.try(stack_push(_, cpu.pc |> program_counter.get_value))
}

fn set_value_at_v(cpu: CPU, vx: Int, value: Int) -> Result(CPU, CPUError) {
  use new_variable_registers <- result.try(
    cpu.variable_registers
    |> variable_registers.set_value(vx, value)
    |> from_variable_registers_error,
  )

  Ok(CPU(..cpu, variable_registers: new_variable_registers))
}

fn get_value_of_v(cpu: CPU, vx: Int) -> Result(Int, CPUError) {
  cpu.variable_registers
  |> variable_registers.get_value(vx)
  |> from_variable_registers_error
}

fn set_pc(cpu: CPU, nnn: Int) -> Result(CPU, CPUError) {
  use new_pc <- result.try(
    cpu.pc |> program_counter.set_value(nnn) |> from_program_counter_error,
  )

  Ok(CPU(..cpu, pc: new_pc))
}

fn clear_screen(cpu: CPU) -> Result(CPU, CPUError) {
  use display_buffer <- result.try(
    cpu.display_buffer
    |> display_buffer.clear
    |> from_display_buffer_error,
  )

  Ok(CPU(..cpu, display_buffer:))
}

pub fn split(num: Int) -> Result(#(Int, Int, Int), Nil) {
  use <- bool.guard(when: num < 0, return: Error(Nil))
  let num = num % 1000
  let hundreds = { num % 1000 } / 100
  let tens = { num - { hundreds * 100 } } / 10
  let ones = num % 10

  Ok(#(hundreds, tens, ones))
}

fn return(cpu: CPU) -> Result(CPU, CPUError) {
  cpu |> stack_pop
}

pub fn tick(cpu: CPU) -> Result(CPU, CPUError) {
  let CPU(sound_timer:, delay_timer:, ..) = cpu
  use new_sound_timer <- result.try(
    sound_timer |> timer.tick |> from_timer_error,
  )

  use new_delay_timer <- result.try(
    delay_timer |> timer.tick |> from_timer_error,
  )

  CPU(..cpu, sound_timer: new_sound_timer, delay_timer: new_delay_timer) |> Ok
}

pub fn stack_push(cpu: CPU, old_pc_value: Int) -> Result(CPU, CPUError) {
  use new_stack <- result.try(
    cpu.stack |> stack.push(old_pc_value) |> from_stack_error,
  )
  CPU(..cpu, stack: new_stack) |> Ok
}

pub fn stack_pop(cpu: CPU) -> Result(CPU, CPUError) {
  use #(new_pc_value, new_stack) <- result.try(
    cpu.stack |> stack.pop |> from_stack_error,
  )
  CPU(..cpu, stack: new_stack) |> set_pc(new_pc_value)
}

pub fn extract_display(cpu: CPU) -> Result(List(List(Bool)), Nil) {
  cpu.display_buffer |> display_buffer.render
}

pub fn load_rom(old_cpu: CPU, rom: List(Int)) {
  let offset = 0x200

  use new_cpu, index_value, index <- list.index_fold(rom, Ok(old_cpu))
  new_cpu |> result.try(set_memory_at(_, index + offset, index_value))
}
