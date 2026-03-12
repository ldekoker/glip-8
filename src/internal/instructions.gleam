import gleam/int
import gleam/result
import utils

pub opaque type Instruction {
  ExecuteMachineLanguageSubroutineAtAddress(nnn: Int)
  ClearScreen
  Return
  JumpToAddress(nnn: Int)
  ExecuteSubroutineAtAddress(nnn: Int)
  SkipNextIfVXEqualsNN(vx: Int, nn: Int)
  SkipNextIfVXNotEqualsNN(vx: Int, nn: Int)
  SkipNextIfVXEqualsVY(vx: Int, vy: Int)
  StoreNNinVX(nn: Int, vx: Int)
  AddNNtoVX(nn: Int, vx: Int)
  StoreVYinVX(vy: Int, vx: Int)
  SetVXtoVXorVY(vx: Int, vy: Int)
  SetVXtoVXandVY(vx: Int, vy: Int)
  SetVXtoVXxorVR(vx: Int, vy: Int)
  AddVYtoVXCarry(vx: Int, vy: Int)
  SubtractVYfromVXBorrow(vx: Int, vy: Int)
  StoreVYinVXBitShiftedRight(vx: Int, vy: Int)
  SetVXtoVYminusVXBorrow(vx: Int, vy: Int)
  StoreVYinVXBitShiftedLeft(vx: Int, vy: Int)
  SkipNextIfVXNotEqualsVY(vx: Int, vy: Int)
  StoreAddressInI(nnn: Int)
  JumpToNNNPlusV0(nnn: Int)
  SetVXToRand(vx: Int, mask: Int)
  Draw(vx: Int, vy: Int, n: Int)
  SkipNextIfKeyPressed(vx: Int)
  SkipNextIfKeyNotPressed(vx: Int)
  StoreDelayTimerInVX(vx: Int)
  OnKeypressStoreInVX(vx: Int)
  SetDelayTimerToVX(vx: Int)
  SetSoundTimerToVX(vx: Int)
  AddVXtoI(vx: Int)
  SetItoSpriteAddress(vx: Int)
  StoreDecimalisedVXInIs(vx: Int)
  StoreMemory(vx: Int)
  LoadMemory(vx: Int)
}

pub opaque type InstructionError {
  InvalidOpcode(opcode: Int)
}

pub fn decode_instruction(value: Int) -> Result(Instruction, InstructionError) {
  // Split the Opcode into four 4-bit nibbles
  use #(category, vx, vy, n) <- result.try(
    value
    |> utils.split_16_bit_to_hexadecimal
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
        3 -> Ok(SetVXtoVXxorVR(vx:, vy:))
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
        0x29 -> Ok(SetItoSpriteAddress(vx:))
        0x33 -> Ok(StoreDecimalisedVXInIs(vx:))
        0x55 -> Ok(StoreMemory(vx:))
        0x65 -> Ok(LoadMemory(vx:))
        _ -> Error(InvalidOpcode(opcode: value))
      }
    }
    _ -> Error(InvalidOpcode(opcode: value))
  }
}
