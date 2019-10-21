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
imports LIST
configuration
      <yul>
      <k> .K </k>
      <vars> .Map </vars>
      <funcs> .K //TODO
      </funcs>
      <envStack> .List </envStack>
      <control> .K </control>
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

//Yul execution proceeds in the following steps
//0. Split program in first scope and continuation, enter first scope.
//1. Search the current scope for functions and put them in the <functions> cell
//2. Execute current scope until halt
//3. Repeat with program := continuation

rule <k> { STMTS } => #pushEnv ~> #findFunctions STMTS ~> STMTS ~> #popEnv ... </k> [tag({mod})]

rule <k> #findFunctions function A() DEF ST:Stmts => #findFunctions ST ... </k>
//TODO: add it to the <funcs> cell

rule <k> #findFunctions S:Stmt ST:Stmts => #findFunctions ST ... </k> [owise, tag({mod})]

rule <k> #findFunctions .Stmts => .K ...  </k> [tag({mod})]

//If we encounter a function definition during the execution phase
//we simply step over it
rule <k> function A() DEF => .K ... </k> [tag({mod})]

rule <k> for { STMTS } COND { END } { BODY } ~> CONT => #pushEnv ~> STMTS ~> #for COND ( BODY +Stmts END ) ~> #popEnv </k> 
     <control> CT => CONT ~> CT </control> [tag({mod})]

rule <k> #pushEnv => .K ... </k>
     <vars> VARS </vars>
     <funcs> FUNCS </funcs>
     <envStack> (.List => ListItem(Env(VARS, FUNCS))) ... </envStack> [tag({mod})]

rule <k> #for COND ( BODY ) => #if COND ( BODY +Stmts ( #for COND ( BODY ) .Stmts) ) ... </k> [tag({mod})]

//The internal #if construct separates the control flow from scoping rules
rule <k> if COND { BODY }  => #pushEnv ~> #if COND ( BODY ) ~> #popEnv  ... </k> [tag({mod})]

rule <k> #if COND ( BODY ) => .K ... </k>
requires COND ==Int 0                 [tag({mod})]

rule <k> #if COND ( BODY ) => BODY ... </k>
requires COND =/=Int 0                [tag({mod})]

rule <k> break ~> _ => .K </k> [tag({mod})]

rule <k> .K => CONT </k>
     <control> CONT => .K </control> [tag({mod})]

rule <k> #popEnv => .K ... </k>
     <vars> OLDVARS => removeAll(OLDVARS, keys(OLDVARS) -Set keys(VARS)) </vars>
     <funcs> _ => FUNCS </funcs>
     <envStack> (ListItem(Env(VARS, FUNCS)) => .List) ...  </envStack> [tag({mod})]

// rule <k> continue ~> INNER ~> #for COND END BODY => #for COND END BODY ... </k> [tag({mod})]
// rule <k> continue ~> #for COND END BODY => #for COND END BODY ... </k>          [tag({mod})]

rule <k> ST STMTS:Stmts => ST ~> STMTS ... </k> requires STMTS =/=K .Stmts [tag({mod})]
rule <k> ST .Stmts => ST ... </k> [tag({mod})]
rule <k> .Stmts => .K ... </k> [tag({mod})]
```
### Variable handling

```k
rule <k> let X := Y:Int => . ... </k>
     <vars> VARS => VARS [X <- Y] </vars>
     requires notBool X in_keys(VARS)              [tag({mod})]

rule <k> let X => . ... </k>
     <vars> VARS => VARS [X <- 0] </vars>
     requires notBool X in_keys(VARS)              [tag({mod})]

rule <k> X := Y:Int => . ... </k>
     <vars> VARS => VARS [X <- Y] </vars>
     requires X in_keys(VARS)                      [tag({mod})]

rule <k> X:Id => VAL ... </k>
     <vars> (X |-> VAL) M </vars>                  [tag({mod})]

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
rule <k> add(HOLE, E2) => HOLE ~> #addi2(E2) ... </k>     [tag({mod}), heat, concrete]
rule <k> HOLE ~> #addi2(E2) => add(HOLE, E2) ... </k>     [tag({mod}), cool, concrete]
rule <k> add(I1:Int, HOLE) => HOLE ~> #addi1(I1) ... </k> [tag({mod}), heat, concrete]
rule <k> HOLE ~> #addi1(I1) => add(I1, HOLE) ... </k>     [tag({mod}), cool, concrete]

rule <k> lt(HOLE, E2) => HOLE ~> #lti2(E2) ... </k>     [tag({mod}), heat, concrete]
rule <k> HOLE ~> #lti2(E2) => lt(HOLE, E2) ... </k>     [tag({mod}), cool, concrete]
rule <k> lt(I1:Int, HOLE) => HOLE ~> #lti1(I1) ... </k> [tag({mod}), heat, concrete]
rule <k> HOLE ~> #lti1(I1) => lt(I1, HOLE) ... </k>     [tag({mod}), cool, concrete]

rule <k> sstore(HOLE, E2) => HOLE ~> #sstorei2(E2) ... </k>     [tag({mod}), heat, concrete]
rule <k> HOLE ~> #sstorei2(E2) => sstore(HOLE, E2) ... </k>     [tag({mod}), cool, concrete]
rule <k> sstore(I1:Int, HOLE) => HOLE ~> #sstorei1(I1) ... </k> [tag({mod}), heat, concrete]
rule <k> HOLE ~> #sstorei1(I1) => sstore(I1, HOLE) ... </k>     [tag({mod}), cool, concrete]

rule <k> iszero(HOLE) => HOLE ~> #iszeroi ... </k>     [tag({mod}), heat, concrete]
rule <k> I1:Int ~> #iszeroi => iszero(I1) ... </k>     [tag({mod}), cool, concrete]

rule <k> #if HOLE ( BODY ) => HOLE ~> #ifi(BODY) ... </k>    [tag({mod}), heat, concrete]
rule <k> I1:Int ~> #ifi(BODY) => #if I1 ( BODY ) ... </k>    [tag({mod}), cool, concrete]

//TODO: multiple assignment
rule <k> let VAR := HOLE => HOLE ~> #leti(VAR) ... </k>     [tag({mod}), heat, concrete]
rule <k> I1:Int ~> #leti(VAR) => let VAR := I1 ... </k>     [tag({mod}), cool, concrete]

rule <k> VAR := HOLE => HOLE ~> #assign(VAR) ... </k>     [tag({mod}), heat, concrete]
rule <k> I1:Int ~> #assign(VAR) => VAR := I1 ... </k>     [tag({mod}), cool, concrete]
endmodule
```

