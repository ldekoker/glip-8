import gleam/bool

/// A 16-bit register.
pub opaque type AddressRegister {
  AddressRegister(Int)
}

pub type AddressRegisterError {
  ValueOverflow(Int)
}

pub fn new(value: Int) -> Result(AddressRegister, AddressRegisterError) {
  use <- bool.guard(when: value >= 65_536, return: Error(ValueOverflow(value)))
  value |> AddressRegister |> Ok
}

pub fn set_value(
  _: AddressRegister,
  new_value: Int,
) -> Result(AddressRegister, AddressRegisterError) {
  use <- bool.guard(
    when: new_value >= 65_536,
    return: Error(ValueOverflow(new_value)),
  )
  new_value |> AddressRegister |> Ok
}

pub fn get_value(address_register: AddressRegister) -> Int {
  let AddressRegister(value) = address_register
  value
}
// TODO handle errors
