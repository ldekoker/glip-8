import chip8/cpu/display_buffer.{type DisplayBuffer}
import chip8/cpu/keypad.{type KeyPad}
import chip8/font_file.{FontFile}
import chip8/instructions as i
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/result

// CONSTANTS ----------------------------------------------------------

const sixteen_bit = 65_536

const twelve_bit = 4096

const eight_bit = 256

const address_register_limit = sixteen_bit

const pc_limit = twelve_bit

const stack_limit = sixteen_bit

const memory_address_limit = twelve_bit

const memory_value_limit = eight_bit

const timer_limit = eight_bit

const variable_registers_value_limit = eight_bit

const variable_registers_address_limit = 16

// TYPES --------------------------------------------------------------

pub opaque type CPU {
  CPU(
    behaviour_flags: CPUBehaviourFlags,
    pc: Int,
    address_register: Int,
    variable_registers: dict.Dict(Int, Int),
    delay_timer: Int,
    sound_timer: Int,
    stack: List(Int),
    keypad: KeyPad,
    memory: dict.Dict(Int, Int),
    display_buffer: DisplayBuffer,
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
  RegisterOverflow(Int)
  RegisterUnderflow(Int)
  TriedToAccessFakeRegister(Int)
  PCValueUnderflow(Int)
  TimerUnderflow(Int)
  TODO
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

fn from_keypad_error(
  result: Result(a, keypad.KeyPadError),
) -> Result(a, CPUError) {
  use error <- result.map_error(result)
  case error {
    keypad.TriedToAccessFakeKey(key) -> TriedToAccessFakeKey(key)
  }
}

// CPU OPERATIONS -----------------------------------------------------

pub fn new(config: CPUConfig) -> Result(CPU, CPUError) {
  let memory = dict.new()
  let variable_registers = dict.new()
  let address_register = 0
  let delay_timer = 0
  let sound_timer = 0
  use display_buffer <- result.try(
    display_buffer.new() |> from_display_buffer_error,
  )
  let keypad = keypad.new()
  let pc = 0x200
  let stack = []

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

pub fn load_rom(cpu: CPU, rom: List(Int)) {
  let offset = 0x200

  list.index_fold(rom, Ok(cpu), fn(cpu, rom_at_index, index) {
    cpu |> result.try(set_memory_at(_, index + offset, rom_at_index))
  })
}

pub fn run(cpu: CPU) -> Result(CPU, CPUError) {
  use instruction <- result.try(fetch_and_decode_instruction(cpu))
  use new_cpu <- result.try(cpu |> increment_pc(2))

  new_cpu |> apply_instruction(instruction)
}

fn fetch_and_decode_instruction(cpu: CPU) -> Result(i.Instruction, CPUError) {
  use byte1 <- result.try(cpu |> get_memory_at(cpu.pc))
  use byte2 <- result.try(
    cpu
    |> get_memory_at(cpu.pc + 1),
  )

  // {byte1}{byte2}, e.g {0xA2}{0x03} = 0x{A203}
  let opcode = byte1 |> int.bitwise_shift_left(8) |> int.bitwise_or(byte2)

  i.decode_instruction(opcode)
  |> result.map_error(fn(error) {
    case error {
      i.InvalidOpcode(opcode:) -> DecodeError(opcode)
    }
  })
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
      use truncated_sum <- result.try(
        int.modulo(sum, variable_registers_value_limit)
        |> result.replace_error(FailedToSetV(vx)),
      )
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
      use value <- result.try(case cpu.behaviour_flags.bit_shift_flag {
        False -> cpu |> get_value_of_v(vy)
        True -> cpu |> get_value_of_v(vx)
      })

      let most_significant_bit =
        value |> int.bitwise_and(0b10000000) |> int.bitwise_shift_right(7)

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
      let delay_timer_value = cpu.delay_timer

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

/// Sets Program Counter to NNN and saves current PC value to call stack.
fn call(cpu: CPU, nnn: Int) -> Result(CPU, CPUError) {
  cpu
  |> set_pc(nnn)
  |> result.try(stack_push(_, cpu.pc))
}

fn return(cpu: CPU) -> Result(CPU, CPUError) {
  cpu |> stack_pop
}

// Skips the next instruction if the boolean is True.
fn skip_if(cpu: CPU, bool: Bool) -> Result(CPU, CPUError) {
  case bool {
    True -> cpu |> increment_pc(2)
    False -> cpu |> Ok
  }
}

// CPU CONFIG OPERATIONS ----------------------------------------------
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

// PC OPERATIONS ------------------------------------------------------

fn set_pc(cpu: CPU, nnn: Int) -> Result(CPU, CPUError) {
  use new_pc <- result.try(
    nnn |> int.modulo(pc_limit) |> result.replace_error(TODO),
  )

  Ok(CPU(..cpu, pc: new_pc))
}

fn increment_pc(cpu: CPU, by value: Int) -> Result(CPU, CPUError) {
  use new_pc <- result.try(
    { cpu.pc + value } |> int.modulo(pc_limit) |> result.replace_error(TODO),
  )

  CPU(..cpu, pc: new_pc) |> Ok
}

// ADDRESS REGISTER OPERATIONS ----------------------------------------

fn get_address_register_value(cpu: CPU) -> Int {
  cpu.address_register
}

fn set_address_register(cpu: CPU, new_value: Int) -> Result(CPU, CPUError) {
  use new_address_register <- result.try(
    new_value
    |> int.modulo(address_register_limit)
    |> result.replace_error(TODO),
  )

  Ok(CPU(..cpu, address_register: new_address_register))
}

// VARIABLE REGISTERS OPERATIONS --------------------------------------

fn set_value_at_v(cpu: CPU, vx: Int, value: Int) -> Result(CPU, CPUError) {
  use value <- result.try(
    value
    |> int.modulo(variable_registers_value_limit)
    |> result.replace_error(TODO),
  )
  use address <- result.try(
    vx
    |> int.modulo(variable_registers_address_limit)
    |> result.replace_error(TODO),
  )
  let new_variable_registers =
    cpu.variable_registers |> dict.insert(address, value)

  Ok(CPU(..cpu, variable_registers: new_variable_registers))
}

fn get_value_of_v(cpu: CPU, vx: Int) -> Result(Int, CPUError) {
  use vx <- result.try(
    vx
    |> int.modulo(variable_registers_address_limit)
    |> result.replace_error(TODO),
  )

  cpu.variable_registers
  |> dict.get(vx)
  |> result.unwrap(0)
  |> Ok
}

// TIMER OPERATIONS ---------------------------------------------------

pub fn tick(cpu: CPU) -> Result(CPU, CPUError) {
  let CPU(sound_timer:, delay_timer:, ..) = cpu
  let new_sound_timer = int.max(sound_timer - 1, 0)
  let new_delay_timer = int.max(delay_timer - 1, 0)

  CPU(..cpu, sound_timer: new_sound_timer, delay_timer: new_delay_timer) |> Ok
}

fn set_delay_timer(cpu: CPU, new_value: Int) -> Result(CPU, CPUError) {
  use new_timer <- result.try(
    new_value |> int.modulo(timer_limit) |> result.replace_error(TODO),
  )

  Ok(CPU(..cpu, delay_timer: new_timer))
}

fn set_sound_timer(cpu: CPU, new_value: Int) -> Result(CPU, CPUError) {
  use new_timer <- result.try(
    new_value |> int.modulo(timer_limit) |> result.replace_error(TODO),
  )

  Ok(CPU(..cpu, sound_timer: new_timer))
}

// STACK OPERATIONS ---------------------------------------------------

pub fn stack_push(cpu: CPU, old_pc_value: Int) -> Result(CPU, CPUError) {
  use new_top <- result.try(
    old_pc_value |> int.modulo(stack_limit) |> result.replace_error(TODO),
  )
  let new_stack = [new_top, ..cpu.stack]

  CPU(..cpu, stack: new_stack) |> Ok
}

pub fn stack_pop(cpu: CPU) -> Result(CPU, CPUError) {
  case cpu.stack {
    [] -> Error(PopFromEmptyStack)
    [top, ..rest] -> CPU(..cpu, stack: rest) |> set_pc(top)
  }
}

// KEYPAD OPERATIONS --------------------------------------------------

/// Gets the first pressed key in numeric order.
fn get_pressed_key(cpu: CPU) -> Result(Int, Nil) {
  cpu.keypad |> keypad.get_pressed
}

fn is_key_pressed(cpu: CPU, key: Int) -> Result(Bool, CPUError) {
  cpu.keypad |> keypad.is_pressed(key) |> from_keypad_error
}

// MEMORY OPERATIONS --------------------------------------------------

fn get_memory_at(cpu: CPU, address address: Int) -> Result(Int, CPUError) {
  use address <- result.try(
    address |> int.modulo(memory_address_limit) |> result.replace_error(TODO),
  )
  cpu.memory
  |> dict.get(address)
  |> result.unwrap(0)
  |> Ok
}

fn set_memory_at(
  cpu: CPU,
  address address: Int,
  to value: Int,
) -> Result(CPU, CPUError) {
  use address <- result.try(
    address |> int.modulo(memory_address_limit) |> result.replace_error(TODO),
  )
  use value <- result.try(
    value |> int.modulo(memory_value_limit) |> result.replace_error(TODO),
  )
  let new_memory =
    cpu.memory
    |> dict.insert(address, value)

  Ok(CPU(..cpu, memory: new_memory))
}

// DISPLAY BUFFER OPERATIONS ------------------------------------------

fn draw(cpu: CPU, vx: Int, vy: Int, n: Int) -> Result(CPU, CPUError) {
  let i = cpu |> get_address_register_value
  use starting_x_coord <- result.try(
    cpu
    |> get_value_of_v(vx)
    |> result.try(fn(x) { x |> int.modulo(64) |> result.replace_error(TODO) }),
  )
  use starting_y_coord <- result.try(
    cpu
    |> get_value_of_v(vy)
    |> result.try(fn(y) { y |> int.modulo(32) |> result.replace_error(TODO) }),
  )

  let ending_y_coord = int.min(starting_y_coord + n, 32)
  // exclusive
  let range = ending_y_coord - starting_y_coord

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

fn clear_screen(cpu: CPU) -> Result(CPU, CPUError) {
  use display_buffer <- result.try(
    cpu.display_buffer
    |> display_buffer.clear
    |> from_display_buffer_error,
  )

  Ok(CPU(..cpu, display_buffer:))
}

pub fn extract_display(cpu: CPU) -> Result(List(List(Bool)), Nil) {
  cpu.display_buffer |> display_buffer.render
}

// MISCELLANEOUS ------------------------------------------------------

pub fn split(num: Int) -> Result(#(Int, Int, Int), Nil) {
  use <- bool.guard(when: num < 0, return: Error(Nil))
  use num <- result.try(num |> int.modulo(1000))
  let hundreds = { num } / 100
  let tens = { num - { hundreds * 100 } } / 10
  use ones <- result.try(num |> int.modulo(10))

  Ok(#(hundreds, tens, ones))
}
