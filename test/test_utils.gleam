import qcheck

pub fn int_lt(x: Int) -> qcheck.Generator(Int) {
  use rand <- qcheck.map(qcheck.small_strictly_positive_int())
  x - rand
}

pub fn int_ge(x: Int) -> qcheck.Generator(Int) {
  use rand <- qcheck.map(qcheck.small_non_negative_int())
  rand + x
}
