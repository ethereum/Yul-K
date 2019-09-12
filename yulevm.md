### Semantics of yul

### Control flow

All instances of `{mod}` will be replaced before kompilation to either `a` or `b` in order to 
construct bisimilarity proofs between two different semantics.

```k
requires "yul-syntax.k"

module YULEVM-{MOD}
imports YUL-SYNTAX
imports BYTES
imports MAP
configuration
      <yul>
      <k> .K /*$PGM*/ </k>
      <varStore> .Map </varStore>
      <storage> .Map </storage> //TODO: multiple accounts
      <callState>
          <memory> .Map </memory> //TODO: just Bytes instead?
          <callDepth> 0      </callDepth>
          <acct>      0      </acct>      // I_a
//          <program>   .Code  </program>   // I_b
          <caller>    0      </caller>    // I_s
          <callData>  .Bytes </callData>  // I_d
          <callValue> 0      </callValue> // I_v
          <gas>       0      </gas>       // \mu_g
      </callState>
      </yul>



rule <k> for { STMTS } COND END BODY => STMTS ~> #for COND END BODY ~> #resetEnv STORE ... </k>
     <varStore> STORE </varStore> [tag({mod})]

rule <k> #for COND END BODY => if COND { BODY END #for COND END BODY } ... </k> [tag({mod})]

rule <k> if COND BODY => .K ... </k>
requires COND ==Int 0                 [tag({mod})]

rule <k> if COND BODY => BODY ... </k>
requires COND =/=Int 0                [tag({mod})]

rule <k> break ~> #for COND END BODY => .K ... </k> [tag({mod})]
rule <k> break ~> ST:Stmt => break ... </k> [owise, tag({mod})]

rule <k> continue ~> INNER ~> #for COND END BODY => #for COND END BODY ... </k> [tag({mod})]
rule <k> continue ~> #for COND END BODY => #for COND END BODY ... </k>          [tag({mod})]

rule <k> ... ST STMTS:Stmts => ST ~> STMTS ... </k> [tag({mod}), structural]
rule <k> ... .Stmts => .K ... </k> [tag({mod}), structural]
```
### Variable handling

```k
rule <k> { B } => B ~> #resetEnv STORE ... </k>
     <varStore> STORE </varStore>                                                 [tag({mod})]
rule <k> #resetEnv OLDSTORE => .K ... </k>
<varStore> STORE => removeAll(STORE, keys(STORE) -Set keys(OLDSTORE)) </varStore> [tag({mod})]


rule <k> let X := Y:Int => . ... </k>
     <varStore> VARS => VARS [X <- Y] </varStore>
     requires notBool X in_keys(VARS)                       [tag({mod})]

rule <k> let X => . ... </k>
     <varStore> VARS => VARS [X <- 0] </varStore>
     requires notBool X in_keys(VARS)                       [tag({mod})]

rule <k> X := Y:Int => . ... </k>
     <varStore> VARS => VARS [X <- Y] </varStore>
     requires X in_keys(VARS)                               [tag({mod})]

rule <k> X:Id => VAL ... </k>
     <varStore> (X |-> VAL) M </varStore>                   [tag({mod})]

```
### Storage operations

```k
rule <k> sstore(X:Int, Y:Int) => . ... </k>
<storage> M:Map => M [X <- Y] </storage>                    [tag({mod})]

rule <k> sload(X:Int) => Y ... </k>
<storage> (X |-> Y) M:Map </storage>                        [tag({mod})]
```



### Arithmetic

```k
rule <k> add(X, Y)  => X +Word Y ... </k>            [tag({mod})]
rule <k> sub(X, Y)  => X -Word Y ... </k>            [tag({mod})]
rule <k> mul(X, Y)  => X *Word Y ... </k>            [tag({mod})]
rule <k> divu(X, Y) => X /Word Y ... </k>            [tag({mod})]
//TODO: signed operators
rule <k> mod(X, Y)  => X %Word Y ... </k>            [tag({mod})]
rule <k> lt(X, Y)   => X <Word Y ... </k>            [tag({mod})]
rule <k> gt(X, Y)   => X >Word Y ... </k>            [tag({mod})]
rule <k> iszero(X)  => bool2Word(X ==Int 0) ... </k> [tag({mod})]
rule <k> or(X, Y)   => X |Word Y ... </k>            [tag({mod})]
rule <k> xor(X, Y)  => X xorWord Y ... </k>          [tag({mod})]
rule <k> and(X, Y)  => X &Word Y ... </k>            [tag({mod})]
```


### Hex


```k
rule <k> X:HexNumber => #parseHexWord(#parseHexString(X)) ... </k> [tag({mod})]
```
### Memory
```k
//Todo: wrap around memory
rule <k> mstore(X, Y) => . ... </k>
     <memory> MEM => MEM [X := padLeftBytes(Int2Bytes(Y, BE, Unsigned), 32, 0)] </memory> [tag({mod})]

rule <k> mload(X) => Bytes2Int(#range(MEM, X, 32), BE, Unsigned) ... </k>
<memory> MEM </memory> [tag({mod})]


```
### Heating and cooling rules

Ideally, these would be generated automatically by future version of K.

```k
rule <k> add(HOLE, E2) => HOLE ~> #addi2(E2) ... </k>     [tag({mod}), heat]
rule <k> HOLE ~> #addi2(E2) => add(HOLE, E2) ... </k>     [tag({mod}), cool]
rule <k> add(I1:Int, HOLE) => HOLE ~> #addi1(I1) ... </k> [tag({mod}), heat]
rule <k> HOLE ~> #addi1(I1) => add(I1, HOLE) ... </k>     [tag({mod}), cool]

rule <k> lt(HOLE, E2) => HOLE ~> #lti2(E2) ... </k>     [tag({mod}), heat]
rule <k> HOLE ~> #lti2(E2) => lt(HOLE, E2) ... </k>     [tag({mod}), cool]
rule <k> lt(I1:Int, HOLE) => HOLE ~> #lti1(I1) ... </k> [tag({mod}), heat]
rule <k> HOLE ~> #lti1(I1) => lt(I1, HOLE) ... </k>     [tag({mod}), cool]

rule <k> sstore(HOLE, E2) => HOLE ~> #sstorei2(E2) ... </k>     [tag({mod}), heat]
rule <k> HOLE ~> #sstorei2(E2) => sstore(HOLE, E2) ... </k>     [tag({mod}), cool]
rule <k> sstore(I1:Int, HOLE) => HOLE ~> #sstorei1(I1) ... </k> [tag({mod}), heat]
rule <k> HOLE ~> #sstorei1(I1) => sstore(I1, HOLE) ... </k>     [tag({mod}), cool]

rule <k> iszero(HOLE) => HOLE ~> #iszeroi ... </k>     [tag({mod}), heat]
rule <k> I1:Int ~> #iszeroi => iszero(I1) ... </k>     [tag({mod}), cool]

rule <k> if HOLE BODY => HOLE ~> #ifi(BODY) ... </k>     [tag({mod}), heat]
rule <k> I1:Int ~> #ifi(BODY) => if I1 BODY ... </k>     [tag({mod}), cool]

rule <k> if HOLE BODY => HOLE ~> #ifi(BODY) ... </k>     [tag({mod}), heat]
rule <k> I1:Int ~> #ifi(BODY) => if I1 BODY ... </k>     [tag({mod}), cool]

//TODO: multiple assignment
rule <k> let VAR := HOLE => HOLE ~> #leti(VAR) ... </k>     [tag({mod}), heat]
rule <k> I1:Int ~> #leti(VAR) => let VAR := I1 ... </k>     [tag({mod}), cool]

rule <k> VAR := HOLE => HOLE ~> #assign(VAR) ... </k>     [tag({mod}), heat]
rule <k> I1:Int ~> #assign(VAR) => VAR := I1 ... </k>     [tag({mod}), cool]
endmodule
```

