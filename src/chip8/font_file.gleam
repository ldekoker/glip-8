import gleam/dynamic/decode

pub const base_font: FontFile = FontFile(
  zero: #(0xF0, 0x90, 0x90, 0x90, 0xF0),
  one: #(0x20, 0x60, 0x20, 0x20, 0x70),
  two: #(0xF0, 0x10, 0xF0, 0x80, 0xF0),
  three: #(0xF0, 0x10, 0xF0, 0x10, 0xF0),
  four: #(0x90, 0x90, 0xF0, 0x10, 0x10),
  five: #(0xF0, 0x80, 0xF0, 0x10, 0xF0),
  six: #(0xF0, 0x80, 0xF0, 0x90, 0xF0),
  seven: #(0xF0, 0x10, 0x20, 0x40, 0x40),
  eight: #(0xF0, 0x90, 0xF0, 0x90, 0xF0),
  nine: #(0xF0, 0x90, 0xF0, 0x10, 0xF0),
  a: #(0xF0, 0x90, 0xF0, 0x90, 0x90),
  b: #(0xE0, 0x90, 0xE0, 0x90, 0xE0),
  c: #(0xF0, 0x80, 0x80, 0x80, 0xF0),
  d: #(0xE0, 0x90, 0x90, 0x90, 0xE0),
  e: #(0xF0, 0x80, 0xF0, 0x80, 0xF0),
  f: #(0xF0, 0x80, 0xF0, 0x80, 0x80),
)

pub type FontFile {
  FontFile(
    zero: Char,
    one: Char,
    two: Char,
    three: Char,
    four: Char,
    five: Char,
    six: Char,
    seven: Char,
    eight: Char,
    nine: Char,
    a: Char,
    b: Char,
    c: Char,
    d: Char,
    e: Char,
    f: Char,
  )
}

pub fn font_file_decoder() -> decode.Decoder(FontFile) {
  use zero <- decode.field("zero", decode_char())
  use one <- decode.field("one", decode_char())
  use two <- decode.field("two", decode_char())
  use three <- decode.field("three", decode_char())
  use four <- decode.field("four", decode_char())
  use five <- decode.field("five", decode_char())
  use six <- decode.field("six", decode_char())
  use seven <- decode.field("seven", decode_char())
  use eight <- decode.field("eight", decode_char())
  use nine <- decode.field("nine", decode_char())
  use a <- decode.field("a", decode_char())
  use b <- decode.field("b", decode_char())
  use c <- decode.field("c", decode_char())
  use d <- decode.field("d", decode_char())
  use e <- decode.field("e", decode_char())
  use f <- decode.field("f", decode_char())
  decode.success(FontFile(
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
  ))
}

fn decode_char() -> decode.Decoder(Char) {
  use a <- decode.field(0, decode.int)
  use b <- decode.field(1, decode.int)
  use c <- decode.field(2, decode.int)
  use d <- decode.field(3, decode.int)
  use e <- decode.field(4, decode.int)

  decode.success(#(a, b, c, d, e))
}

type Char =
  #(Int, Int, Int, Int, Int)
