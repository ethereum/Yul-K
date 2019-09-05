{
  sstore(0, 20)
  let y
  for {let x := 0} lt(x, sload(0)) {x := add(x, 1)} {
     y := add(x, y)
  }
  sstore(1,y)
}