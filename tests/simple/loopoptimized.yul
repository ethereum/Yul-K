{
    let _1 := 20
    sstore(0, _1)
    let x := 0
    let y := x
    for { } 1 { x := add(x, 1) }
    {
        if iszero(lt(x, _1)) { break }
        y := add(x, y)
    }
    sstore(1,y)
}