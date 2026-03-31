import assets/roms
import chip8/cpu
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam_community/colour
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/element/svg
import lustre/event

const roms = [ROM(roms.ibm_game, "IBM"), ROM(roms.windows, "Windows")]

const dimensions = #(64, 32)

type ROM {
  ROM(filepath: List(Int), name: String)
}

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

/// MODEL -------------------------------------------------------------
type Model {
  SelectingRom(selected_rom: ROM, error: option.Option(cpu.CPUError))
  CPULoading
  CPU(cpu.CPU)
}

fn init(_) {
  let assert Ok(rom) = roms |> list.first
  #(SelectingRom(rom, error: option.None), effect.none())
}

/// MESSAGE -----------------------------------------------------------
type Msg {
  UserSelectedRom(rom: ROM)
  RomLoaded(cpu.CPU)
  CPUHadError(cpu.CPUError)
  UserUpdatedSelectRow(rom: ROM)
}

/// UPDATE ------------------------------------------------------------
fn update(_model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSelectedRom(rom:) -> #(CPULoading, load_rom(rom))
    RomLoaded(cpu) -> #(CPU(cpu), tick(cpu))
    CPUHadError(error) -> #(
      SelectingRom(
        selected_rom: roms |> list.first |> result.lazy_unwrap(fn() { panic }),
        error: option.Some(error),
      ),
      effect.none(),
    )
    UserUpdatedSelectRow(rom) -> #(
      SelectingRom(selected_rom: rom, error: option.None),
      effect.none(),
    )
  }
}

/// EFFECTS -----------------------------------------------------------
fn load_rom(rom: ROM) -> Effect(Msg) {
  use dispatch <- effect.from()

  let cpu =
    cpu.new(cpu.Modern)
    |> result.try(cpu.load_rom(_, rom.filepath))

  let assert Ok(cpu) = cpu

  dispatch(RomLoaded(cpu))
}

fn tick(cpu: cpu.CPU) -> Effect(Msg) {
  use dispatch <- effect.from
  use <- set_timeout(1)

  dispatch(case cpu |> cpu.run {
    Ok(cpu) -> RomLoaded(cpu)
    Error(error) -> CPUHadError(error)
  })
}

@external(javascript, "./chip_8_gleam.ffi.mjs", "set_timeout")
fn set_timeout(_delay: Int, _cb: fn() -> a) -> Nil {
  Nil
}

/// VIEW --------------------------------------------------------------
fn view(model: Model) -> element.Element(Msg) {
  html.main([], [
    html.h1([], [html.text("CHIP-8")]),
    case model {
      SelectingRom(rom, error) -> select_rom(rom, error)
      CPULoading -> cpu_loading()
      CPU(cpu) -> display_cpu(cpu)
    },
  ])
}

fn select_rom(
  selected_rom: ROM,
  error: option.Option(cpu.CPUError),
) -> element.Element(Msg) {
  element.fragment([
    html.select(
      [
        attribute.name("select_rom"),
        event.on_change(fn(x) {
          UserUpdatedSelectRow(
            list.find(roms, one_that: fn(r) { r.name == x })
            |> result.lazy_unwrap(fn() { panic }),
          )
        }),
      ],
      list.map(roms, fn(rom) {
        let ROM(filepath, name) = rom
        html.option(
          [
            attribute.value(name),
            case selected_rom.filepath == filepath {
              True -> attribute.selected(True)
              False -> attribute.none()
            },
          ],
          name,
        )
      }),
    ),
    html.button([event.on_click(UserSelectedRom(selected_rom))], [
      html.text("Load" <> selected_rom.name),
    ]),
    html.p([], [
      format_error(error),
    ]),
  ])
}

fn format_error(error: option.Option(cpu.CPUError)) -> element.Element(Msg) {
  html.text(case error {
    option.Some(error) ->
      case error {
        cpu.FailedToInitialiseMemory -> "Failed to Initialise Memory"

        cpu.FailedToFetchMemory(address:) ->
          "Failed To Fetch Memory " <> int.to_string(address)

        cpu.FailedToSetMemory(address:) ->
          "Failed To Set Memory " <> int.to_string(address)

        cpu.FailedToInitialiseVariableRegisters ->
          "Failed To Initialise Variable Registers"

        cpu.FailedToSetV(index) ->
          "Failed To Set V Register " <> int.to_string(index)

        cpu.FailedToGetFromV(index) ->
          "Failed To Get From V Register " <> int.to_string(index)

        cpu.IValueOverflow(value) ->
          "I Register Overflow " <> int.to_string(value)

        cpu.TriedToAccessFakeDisplayRow(row) ->
          "Tried To Access Invalid Display Row " <> int.to_string(row)

        cpu.TimerError -> "Timer Error"

        cpu.FailedToInitialiseKeypad -> "Failed To Initialise Keypad"

        cpu.TriedToAccessFakeKey(key) ->
          "Tried To Access Invalid Key " <> int.to_string(key)

        cpu.PCValueOverflow(value) ->
          "Program Counter Overflow " <> int.to_string(value)

        cpu.FailedToInitialiseStack -> "Failed To Initialise Stack"

        cpu.PushToFullStack -> "Attempted To Push To Full Stack"

        cpu.PopFromEmptyStack -> "Attempted To Pop From Empty Stack"

        cpu.StackValueOverflow(value) ->
          "Stack Value Overflow " <> int.to_string(value)

        cpu.StackError -> "Stack Error"

        cpu.DecodeError(opcode) -> "Decode Error " <> int.to_string(opcode)

        cpu.AttemptToDecimaliseNegativeNumber ->
          "Attempted To Decimalise Negative Number"

        cpu.NotInFont(char:) ->
          "Character Not In Font " <> char |> int.to_string

        cpu.TimerOverflow(value) -> "Timer Overflow " <> int.to_string(value)

        cpu.TriedToAccessFakeDisplayColumn(column) ->
          "Tried To Access Invalid Display Column " <> int.to_string(column)

        cpu.IValueUnderflow(value) ->
          "I Register Underflow " <> int.to_string(value)

        cpu.StackValueUnderflow(value) ->
          "Stack Value Underflow " <> int.to_string(value)

        cpu.DisplayReceivedIncorrectRowLength(length) ->
          "Display Received Incorrect Row Length " <> int.to_string(length)

        cpu.TriedToAccessFakeMemoryAddress(address:) ->
          "Tried To Access Invalid Memory Address " <> int.to_string(address)

        cpu.MemoryOverflow(value:) -> "Memory Overflow " <> int.to_string(value)

        cpu.MemoryUnderflow(value:) ->
          "Memory Underflow " <> int.to_string(value)

        cpu.InternalDisplayBufferError -> "Internal Display Buffer Error"
        cpu.RegisterOverflow(value) ->
          "Register Overflow: " <> value |> int.to_string
        cpu.RegisterUnderflow(value) ->
          "Register Underflow: " <> value |> int.to_string
        cpu.TriedToAccessFakeRegister(register) ->
          "Tried to access invalid register " <> register |> int.to_string
        cpu.PCValueUnderflow(value) ->
          "Program Counter Underflow " <> int.to_string(value)
      }
    option.None -> ""
  })
}

fn cpu_loading() -> element.Element(a) {
  html.text("Loading...")
}

fn display_cpu(cpu: cpu.CPU) -> element.Element(a) {
  let assert Ok(grid) = cpu |> cpu.extract_display
  svg_grid(grid)
}

fn svg_grid(grid: List(List(Bool))) -> element.Element(msg) {
  {
    use squares, row, y_coord <- list.index_fold(grid, [])
    let row =
      {
        use squares, pixel, x_coord <- list.index_fold(row, [])
        let square =
          square(
            [
              attribute_x({ dimensions.0 - x_coord } * 10),
              attribute_y({ dimensions.1 - y_coord } * 10),
              case pixel {
                True -> attribute_svg_fill(colour.red)
                False -> attribute.none()
              },
            ],
            10,
          )
        [square, ..squares]
      }
      |> element.fragment
    [row, ..squares]
  }
  |> svg.svg(
    [
      attribute.width({ dimensions.0 + 1 } * 10),
      attribute.height({ dimensions.1 + 1 } * 10),
    ],
    _,
  )
}

fn square(attributes: List(attribute.Attribute(msg)), side_length: Int) {
  svg.rect([
    attribute.width(side_length),
    attribute.height(side_length),
    ..attributes
  ])
}

fn attribute_x(value: Int) -> attribute.Attribute(msg) {
  attribute.attribute("x", int.to_string(value))
}

fn attribute_y(value: Int) -> attribute.Attribute(msg) {
  attribute.attribute("y", int.to_string(value))
}

fn attribute_svg_fill(colour: colour.Color) -> attribute.Attribute(msg) {
  attribute.attribute("fill", colour |> colour_to_html_colour)
}

fn colour_to_html_colour(colour: colour.Color) {
  "#" <> colour |> colour.to_rgba_hex_string
}
