import gleam/int
import gleam/result
import util

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

pub fn decode_instruction(value: Int) {
  use category <- result.try(util.get_hex_digit(value, 0))
  use vx <- result.try(util.get_hex_digit(value, 1))
  use vy <- result.try(util.get_hex_digit(value, 2))
  use n <- result.try(util.get_hex_digit(value, 3))
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
        // err
        _ -> todo
      }
    9 -> Ok(SkipNextIfVXNotEqualsVY(vx:, vy:))
    0xA -> Ok(StoreAddressInI(nnn:))
    0xB -> Ok(JumpToNNNPlusV0(nnn:))
    0xC -> Ok(SetVXToRand(vx:, mask: nn))
    0xD -> Ok(Draw(vx:, vy:, n:))
    0xE -> todo
    0xF -> todo
    //err
    _ -> todo
  }
}
