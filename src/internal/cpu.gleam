import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import internal/cpu/fixed_length_bit_array
import internal/cpu/stack
import internal/cpu/timer as tim
import internal/font_file.{FontFile}
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
  FailedToSetMemory(address: Int)
  StackPoppedWhenEmpty
  FailedToGetFromV(Int)
  AttemptToDecimaliseNegativeNumber
  TriedToSetPCto(value: Int)
  FailedToSetV(Int)
  TriedToAccessFakeKey(Int)
  NotInFont(char: Int)
  TriedToAccessFakeScreenRow(row: Int)
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

  CPU(
    memory:,
    variable_registers:,
    address_register: 0,
    delay_timer: tim.new(),
    sound_timer: tim.new(),
    display_buffer:,
    keypad:,
    stack: stack.new(),
    pc: 0,
  )
  |> load_font(font_file.base_font)
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
  |> result.try(apply_instruction(cpu |> increment_pc, _))
}

fn increment_pc(cpu: CPU) -> CPU {
  CPU(..cpu, pc: cpu.pc + 2)
}

fn get_memory_at(cpu: CPU, address address: Int) -> Result(Int, CPUError) {
  cpu.memory
  |> fixed_length_bit_array.get_value_at_address(address)
  |> result.replace_error(FailedToFetch(address))
}

fn set_memory_at(
  cpu: CPU,
  address address: Int,
  to value: Int,
) -> Result(CPU, CPUError) {
  use new_memory <- result.try(
    cpu.memory
    |> fixed_length_bit_array.set_value_at_address(address, value)
    |> result.replace_error(FailedToSetMemory(address:)),
  )

  Ok(CPU(..cpu, memory: new_memory))
}

fn fetch_instruction(cpu: CPU) -> Result(Int, CPUError) {
  use byte1 <- result.try(cpu |> get_memory_at(cpu.address_register))
  use byte2 <- result.try(cpu |> get_memory_at(cpu.address_register + 1))
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

      Ok(cpu |> skip_if(val_at_vx == nn))
    }
    i.SkipNextIfVXNotEqualsNN(vx:, nn:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      Ok(cpu |> skip_if(val_at_vx != nn))
    }
    i.SkipNextIfVXEqualsVY(vx:, vy:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      Ok(cpu |> skip_if(val_at_vx == val_at_vy))
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
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      let least_significant_bit = val_at_vy |> int.bitwise_and(0b00000001)

      cpu
      |> set_value_at_v(vx, val_at_vy |> int.bitwise_shift_right(1))
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
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      let most_significant_bit = val_at_vy |> int.bitwise_and(0b10000000)

      cpu
      |> set_value_at_v(vx, val_at_vy |> int.bitwise_shift_left(1))
      |> result.try(set_value_at_v(_, 0xF, most_significant_bit))
    }
    i.SkipNextIfVXNotEqualsVY(vx:, vy:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use val_at_vy <- result.try(cpu |> get_value_of_v(vy))

      Ok(cpu |> skip_if(val_at_vx != val_at_vy))
    }
    i.StoreAddressInI(nnn:) -> {
      Ok(CPU(..cpu, address_register: nnn))
    }
    i.JumpToNNNPlusV0(nnn:) -> {
      // Note: Configurable behaviour desired. Using COSMAC VIP behaviour.
      use val_at_v0 <- result.try(cpu |> get_value_of_v(0x0))

      // TODO: maybe look at integer overflow here?
      let pc = nnn + val_at_v0
      Ok(CPU(..cpu, pc:))
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

      Ok(cpu |> skip_if(key_pressed))
    }
    i.SkipNextIfKeyNotPressed(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use key_pressed <- result.try(cpu |> is_key_pressed(val_at_vx))

      Ok(cpu |> skip_if(!key_pressed))
    }
    i.StoreDelayTimerInVX(vx:) -> {
      let delay_timer_value = cpu.delay_timer |> tim.get_value

      cpu |> set_value_at_v(vx, delay_timer_value)
    }
    i.OnKeypressStoreInVX(vx:) -> {
      case get_pressed_key(cpu) {
        Ok(key) -> {
          cpu |> set_value_at_v(vx, key)
        }
        _ -> {
          Ok(CPU(..cpu, pc: cpu.pc - 2))
        }
      }
    }
    i.SetDelayTimerToVX(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      let new_delay_timer = cpu.delay_timer |> tim.set_value(val_at_vx)

      Ok(CPU(..cpu, delay_timer: new_delay_timer))
    }
    i.SetSoundTimerToVX(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      let new_sound_timer = cpu.sound_timer |> tim.set_value(val_at_vx)

      Ok(CPU(..cpu, sound_timer: new_sound_timer))
    }
    i.AddVXtoI(vx:) -> {
      // Cosmac Behaviour.
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      let i_plus_vx = cpu.address_register + val_at_vx

      Ok(CPU(..cpu, address_register: i_plus_vx))
    }
    i.SetItoFontAddress(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))

      use font_address <- result.try(
        val_at_vx |> int.bitwise_and(0b1111) |> get_font_address,
      )

      Ok(CPU(..cpu, address_register: font_address))
    }
    i.StoreDecimalisedVXInIs(vx:) -> {
      use val_at_vx <- result.try(cpu |> get_value_of_v(vx))
      use #(hundreds, tens, ones) <- result.try(
        split(val_at_vx)
        |> result.replace_error(AttemptToDecimaliseNegativeNumber),
      )

      Ok(cpu)
      |> result.try(set_memory_at(_, cpu.address_register, hundreds))
      |> result.try(set_memory_at(_, cpu.address_register + 1, tens))
      |> result.try(set_memory_at(_, cpu.address_register + 2, ones))
    }
    i.StoreMemory(vx:) -> {
      // COSMAC behaviour incrementing I as we go
      int.range(from: 0, to: vx + 1, with: Ok(cpu), run: fn(maybe_cpu, index) {
        use cpu <- result.try(maybe_cpu)

        // Get v_index register value
        use val_at_v_index: Int <- result.try(cpu |> get_value_of_v(index))

        // Set memory value at I
        use new_cpu <- result.try(
          cpu |> set_memory_at(cpu.address_register, val_at_v_index),
        )

        Ok(CPU(..new_cpu, address_register: cpu.address_register + 1))
      })
    }
    i.LoadMemory(vx:) -> {
      // COSMAC behaviour incrementing I as we go
      int.range(from: 0, to: vx + 1, with: Ok(cpu), run: fn(maybe_cpu, index) {
        use cpu <- result.try(maybe_cpu)

        // Get memory value at I
        use val_at_address <- result.try(
          cpu |> get_memory_at(address: cpu.address_register),
        )

        // Set v_index register
        use new_cpu <- result.try(cpu |> set_value_at_v(index, val_at_address))

        Ok(CPU(..new_cpu, address_register: cpu.address_register + 1))
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

/// Gets the first pressed key in numeric order.
fn get_pressed_key(cpu: CPU) -> Result(Int, Nil) {
  cpu.keypad |> fixed_length_bit_array.find_index(fn(num) { num == 1 })
}

fn is_key_pressed(cpu: CPU, key: Int) -> Result(Bool, CPUError) {
  fixed_length_bit_array.get_value_at_address(cpu.keypad, key)
  |> result.map(fn(num) { num == 1 })
  |> result.replace_error(TriedToAccessFakeKey(key))
}

// Skips the next instruction if the boolean is True.
fn skip_if(cpu: CPU, bool: Bool) -> CPU {
  case bool {
    True -> cpu |> increment_pc
    False -> cpu
  }
}

// TODO replace behaviour with BigInt
fn draw(cpu: CPU, vx: Int, vy: Int, n: Int) -> Result(CPU, CPUError) {
  use top_left_x <- result.try(
    cpu |> get_value_of_v(vx) |> result.map(fn(num) { num % 64 }),
  )
  use top_left_y <- result.try(
    cpu |> get_value_of_v(vy) |> result.map(fn(num) { num % 32 }),
  )
  // set VF to 0
  use cpu <- result.try(cpu |> set_value_at_v(0xF, 0))
  // for n rows (until the smaller of n + 1 and 33)
  use maybe_cpu, index <- int.range(
    from: 0,
    to: int.max(top_left_y + n + 1, 33),
    with: Ok(cpu),
  )
  use cpu <- result.try(maybe_cpu)

  let x = 56 - top_left_x
  let y = top_left_y + index

  // get the Nth byte of sprite data (so I+N) and shift it left or right
  use sprite_data <- result.try(
    cpu
    |> get_memory_at(cpu.address_register + index)
    |> result.map(int.bitwise_shift_left(_, x)),
  )

  use screen_row <- result.try(cpu |> get_screen_row(y))

  let new_screen_row = sprite_data |> int.bitwise_exclusive_or(screen_row)

  let any_bit_flipped_off =
    new_screen_row
    |> int.bitwise_not
    |> int.bitwise_and(screen_row)
    |> fn(a) {
      case a > 0 {
        True -> 1
        False -> 0
      }
    }

  cpu
  |> set_value_at_v(0xF, any_bit_flipped_off)
  |> result.try(set_screen_row(_, y, new_screen_row))
}

fn get_screen_row(cpu: CPU, y_coord: Int) -> Result(Int, CPUError) {
  cpu.display_buffer
  |> fixed_length_bit_array.get_value_at_address(y_coord)
  |> result.replace_error(TriedToAccessFakeScreenRow(row: y_coord))
}

fn set_screen_row(
  cpu: CPU,
  y_coord: Int,
  new_screen_row: Int,
) -> Result(CPU, CPUError) {
  use new_display_buffer <- result.try(
    cpu.display_buffer
    |> fixed_length_bit_array.set_value_at_address(y_coord, new_screen_row)
    |> result.replace_error(TriedToAccessFakeScreenRow(row: y_coord)),
  )

  Ok(CPU(..cpu, display_buffer: new_display_buffer))
}

/// Sets Program Counter to NNN and saves current PC value to call stack.
fn call(cpu: CPU, nnn: Int) -> Result(CPU, CPUError) {
  use new_cpu <- result.try(cpu |> set_pc(nnn))

  Ok(CPU(..new_cpu, stack: new_cpu.stack |> stack.push(cpu.pc)))
}

fn set_value_at_v(cpu: CPU, vx: Int, nn: Int) -> Result(CPU, CPUError) {
  use new_variable_registers <- result.try(
    cpu.variable_registers
    |> fixed_length_bit_array.set_value_at_address(vx, nn)
    |> result.replace_error(FailedToSetV(vx)),
  )

  Ok(CPU(..cpu, variable_registers: new_variable_registers))
}

fn get_value_of_v(cpu: CPU, vx: Int) -> Result(Int, CPUError) {
  cpu.variable_registers
  |> fixed_length_bit_array.get_value_at_address(vx)
  |> result.replace_error(FailedToGetFromV(vx))
}

fn set_pc(cpu: CPU, nnn: Int) -> Result(CPU, CPUError) {
  use <- bool.guard(
    // pc is 16-bit, and 2 ^ 16 = 65_536
    when: nnn >= 65_536,
    return: Error(TriedToSetPCto(value: nnn)),
  )

  Ok(CPU(..cpu, pc: nnn))
}

fn clear_screen(cpu: CPU) {
  use display_buffer <- result.try(
    fixed_length_bit_array.new(length: 32, bits: 64)
    |> result.replace_error(FailedToInitialise("Display Buffer")),
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
  let #(maybe_stack_address, new_stack) = cpu.stack |> stack.pop()
  use stack_address <- result.try(
    maybe_stack_address |> result.replace_error(StackPoppedWhenEmpty),
  )
  Ok(CPU(..cpu, stack: new_stack, pc: stack_address))
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
