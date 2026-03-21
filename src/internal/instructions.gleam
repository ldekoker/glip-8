import gleam/int
import gleam/result

pub type Instruction {
  /// `0NNN`
  /// 
  /// Vestigial instruction that does nothing.
  ExecuteMachineLanguageSubroutineAtAddress(nnn: Int)
  /// `00E0`
  /// 
  /// Clears the display buffer.
  ClearScreen
  /// `00EE`
  /// 
  /// Returns from a subroutine by popping the previous address from
  /// the stack and setting the program counter to the result.
  Return
  /// `1NNN`
  /// 
  /// Set the program counter to `NNN`
  JumpToAddress(nnn: Int)
  /// `2NNN`
  /// 
  /// Push current program counter value to top of the stack then set
  /// the program counter to `NNN`
  ExecuteSubroutineAtAddress(nnn: Int)
  /// `3XNN`
  /// 
  /// Increment program counter by 2 if the value of register `VX`
  /// equals `NN`
  SkipNextIfVXEqualsNN(vx: Int, nn: Int)
  /// `4XNN`
  /// 
  /// Increment program counter by 2 if the value of register `VX`
  /// does not equal `NN`
  SkipNextIfVXNotEqualsNN(vx: Int, nn: Int)
  /// `5XY0`
  /// 
  /// Increment program counter by 2 if the value of register `VX`
  /// equals `VY`
  SkipNextIfVXEqualsVY(vx: Int, vy: Int)
  /// `6XNN`
  /// 
  /// Set the value of register `VX` to `NN`
  StoreNNinVX(nn: Int, vx: Int)
  /// `7XNN`
  /// 
  /// Set the value of register `VX` to `val_VX` + `NN`.
  AddNNtoVX(nn: Int, vx: Int)
  /// `8XY0`
  /// 
  /// Store the value of register `VY` in register `VX`
  StoreVYinVX(vy: Int, vx: Int)
  /// `8XY1`
  /// 
  /// Set `VX` to `val_VX` OR `val_VY`
  SetVXtoVXorVY(vx: Int, vy: Int)
  /// `8XY2`
  /// 
  /// Set `VX` to `val_VX` AND `val_VY`
  SetVXtoVXandVY(vx: Int, vy: Int)
  /// `8XY3`
  /// 
  /// Set `VX` to `val_VX` XOR `val_VY`
  SetVXtoVXxorVY(vx: Int, vy: Int)
  /// `8XY4`
  /// 
  /// Set `VX` to `val_VX` + `val_VY`. Also, if the result overflows
  /// (i.e is larger than 255), `VF` is set to 1, else it is set to 0.
  AddVYtoVXCarry(vx: Int, vy: Int)
  /// `8XY5`
  ///
  /// First, if `val_VX` > `val_VY`, set `VF` to 1, else 0.
  /// Then, set `VX` to `val_VX` - `val_VY`
  SubtractVYfromVXBorrow(vx: Int, vy: Int)
  /// `8XY6`
  /// 
  /// Store `val_VY` >> 1 in `VX`. Set register `VF` to `val_VY`'s
  /// least significant bit.
  /// - COSMAC: As above
  /// - Alternate: Uses `val_VX` instead of `val_VY`
  StoreVYinVXBitShiftedRight(vx: Int, vy: Int)
  /// `8XY7`
  /// 
  /// First, if `val_VY` > `val_VX`, set `VF` to 1, else 0.
  /// Then, set `VX` to `val_VY` - `val_VX`
  SetVXtoVYminusVXBorrow(vx: Int, vy: Int)
  /// `8XYE`
  /// 
  /// Store `val_VY` << 1 in `VX`. Set register `VF` to `val_VY`'s
  /// most significant bit.
  StoreVYinVXBitShiftedLeft(vx: Int, vy: Int)
  /// `9XY0`
  /// 
  /// Increment program counter by 2 if `val_VX` != `val_VY`
  SkipNextIfVXNotEqualsVY(vx: Int, vy: Int)
  /// `ANNN`
  /// 
  /// The value of the address register is set to `NNN`
  StoreAddressInI(nnn: Int)
  /// `BNNN`
  /// 
  /// Set program counter to `NNN` + `val_V0`
  /// 
  /// - Cosmac: As above
  /// - Alternate: `BXNN`, jump to `val_VX` + `XNN`
  JumpToNNNPlusV0(nnn: Int)
  /// `CXNN`
  /// 
  /// Set `VX` to a random number AND `NN`
  SetVXToRand(vx: Int, mask: Int)
  /// `DXYN`
  /// 
  /// Draw a sprite at position `VX`, `VY`, with `N` bytes of sprite
  /// data starting at the address stored in the address register.
  /// Set VF to 1 if any set pixels are changed to unset, and 0 otherwise.
  Draw(vx: Int, vy: Int, n: Int)
  /// `EX9E`
  /// 
  /// Increment program counter by 2 if key `val_VX` is pressed
  SkipNextIfKeyPressed(vx: Int)
  /// `EXA1`
  /// 
  /// Increment program counter by 2 if key `val_VC` is not pressed
  SkipNextIfKeyNotPressed(vx: Int)
  /// `FX07`
  /// 
  /// Set `VX` to the current value of the delay timer
  StoreDelayTimerInVX(vx: Int)
  /// `FX0A`
  /// 
  /// If a key is pressed, store it in `VX`.
  /// Otherwise, decrement program counter by 2.
  OnKeypressStoreInVX(vx: Int)
  /// `FX15`
  /// 
  /// Set the delay timer to `val_VX`
  SetDelayTimerToVX(vx: Int)
  /// `FX18`
  /// 
  /// Set the sound timer to `val_VX`
  SetSoundTimerToVX(vx: Int)
  /// `FX1E`
  /// 
  /// Set address register to its value + `val_VX`
  /// - Cosmac: As above
  /// - Alternate: Set VF to 1 if address register overflows from 0xFFF
  ///   to above 0x1000
  AddVXtoI(vx: Int)
  /// `FX29`
  /// 
  /// Set the address_register to the memory address corresponding to the
  /// font character corresponding to the hexadecimal digit in `VX`
  SetItoFontAddress(vx: Int)
  /// `FX33`
  /// 
  /// Splits `val_VX` into hundreds, tens, and ones.
  /// Store hundreds in address_register, tens in address_register + 1,
  /// ones in _ + 2.
  StoreDecimalisedVXInIs(vx: Int)
  /// `FX55`
  /// 
  /// Store `val_V0` through `val_VX` in memory at address_register + 0 through
  /// + `VX`
  /// - Cosmac: Mutates the address register..
  /// Alternate: Does not mutate the address register.
  StoreMemory(vx: Int)
  /// `FX65`
  /// 
  /// Store values in memory at address_register + 0 through + `VX` in
  /// `V0` through `VX`
  /// - Cosmac: Mutates the address register..
  /// - Alternate: Does not mutate the address register.
  LoadMemory(vx: Int)
}

pub type InstructionError {
  InvalidOpcode(opcode: Int)
}

/// Decodes 16-bit instructions following the CHIP-8 Spec.
/// If an instruction is invalid, instead returns InvalidOpcode.
pub fn decode_instruction(value: Int) -> Result(Instruction, InstructionError) {
  // Split the Opcode into four 4-bit nibbles
  use #(category, vx, vy, n) <- result.try(
    value
    |> split_16_bit_to_hexadecimal
    |> result.replace_error(InvalidOpcode(opcode: value)),
  )
  let nn = int.bitwise_shift_left(vy, 4) + n
  let nnn = int.bitwise_shift_left(vx, 8) + nn

  case category {
    0 -> {
      case nnn {
        0xE0 -> Ok(ClearScreen)
        0xEE -> Ok(Return)
        _ -> Ok(ExecuteMachineLanguageSubroutineAtAddress(nnn:))
      }
    }
    1 -> Ok(JumpToAddress(nnn:))
    2 -> Ok(ExecuteSubroutineAtAddress(nnn:))
    3 -> Ok(SkipNextIfVXEqualsNN(vx:, nn:))
    4 -> Ok(SkipNextIfVXNotEqualsNN(vx:, nn:))
    5 -> Ok(SkipNextIfVXEqualsVY(vx:, vy:))
    6 -> Ok(StoreNNinVX(nn:, vx:))
    7 -> Ok(AddNNtoVX(nn:, vx:))
    8 ->
      case n {
        0 -> Ok(StoreVYinVX(vy:, vx:))
        1 -> Ok(SetVXtoVXorVY(vx:, vy:))
        2 -> Ok(SetVXtoVXandVY(vx:, vy:))
        3 -> Ok(SetVXtoVXxorVY(vx:, vy:))
        4 -> Ok(AddVYtoVXCarry(vy:, vx:))
        5 -> Ok(SubtractVYfromVXBorrow(vy:, vx:))
        6 -> Ok(StoreVYinVXBitShiftedRight(vy:, vx:))
        7 -> Ok(SetVXtoVYminusVXBorrow(vx:, vy:))
        0xE -> Ok(StoreVYinVXBitShiftedLeft(vy:, vx:))
        _ -> Error(InvalidOpcode(opcode: value))
      }
    9 -> Ok(SkipNextIfVXNotEqualsVY(vx:, vy:))
    0xA -> Ok(StoreAddressInI(nnn:))
    0xB -> Ok(JumpToNNNPlusV0(nnn:))
    0xC -> Ok(SetVXToRand(vx:, mask: nn))
    0xD -> Ok(Draw(vx:, vy:, n:))
    0xE -> {
      case nn {
        0x9E -> Ok(SkipNextIfKeyPressed(vx:))
        0xA1 -> Ok(SkipNextIfKeyNotPressed(vx:))
        _ -> Error(InvalidOpcode(opcode: value))
      }
    }
    0xF -> {
      case nn {
        0x07 -> Ok(StoreDelayTimerInVX(vx:))
        0x0A -> Ok(OnKeypressStoreInVX(vx:))
        0x15 -> Ok(SetDelayTimerToVX(vx:))
        0x18 -> Ok(SetSoundTimerToVX(vx:))
        0x1E -> Ok(AddVXtoI(vx:))
        0x29 -> Ok(SetItoFontAddress(vx:))
        0x33 -> Ok(StoreDecimalisedVXInIs(vx:))
        0x55 -> Ok(StoreMemory(vx:))
        0x65 -> Ok(LoadMemory(vx:))
        _ -> Error(InvalidOpcode(opcode: value))
      }
    }
    _ -> Error(InvalidOpcode(opcode: value))
  }
}

/// Transforms a 16 bit number into a tuple of 4, 4-bit numbers.
/// Otherwise, returns Nil.
fn split_16_bit_to_hexadecimal(num: Int) -> Result(#(Int, Int, Int, Int), Nil) {
  case <<num:16>> {
    <<a:4, b:4, c:4, d:4>> -> Ok(#(a, b, c, d))
    _ -> Error(Nil)
  }
}
