Imports EEI semantics for now

```k
//TODO: import eei.k or roll our own?
//requires "eei.k"
requires "yul.k"
module YULEVM
imports YUL-SYNTAX
//imports EEI

configuration
      <yul>
      <k> $PGM </k>
      <varStore> .Map </varStore>
      <memory> .Map </memory>
      <storage> .Map </storage> //TODO: multiple accounts
      <callState>
          <callDepth> 0      </callDepth>
          <acct>      0      </acct>      // I_a
//          <program>   .Code  </program>   // I_b
          <caller>    0      </caller>    // I_s
          <callData>  .Bytes </callData>  // I_d
          <callValue> 0      </callValue> // I_v
          <gas>       0      </gas>       // \mu_g
      </callState>
      </yul>

```


```k

//rule <k> #newAccount ACCT => . ... </k>
//     <accounts>
//     (.Bag => <account>
//                <id>      ACCT     </id>
//                <balance> 0     </balance>
//                <code>    .Code </code>
//                <storage> .Map  </storage>
//                <nonce>   0     </nonce>
//              </account>)
//              ...
//      </accounts>

```

### Control flow

```k
syntax Stmt ::= "#for" Expr Block Block

rule <k> for { STMTS } COND END BODY => STMTS ~> #for COND END BODY ~> #resetEnv keys(STORE) ... </k>
     <varStore> STORE </varStore>

rule <k> #for COND END BODY => if COND { BODY END #for COND END BODY } ... </k>

rule <k> if COND BODY => .K ... </k>
requires COND ==Int 0

rule <k> if COND BODY => BODY ... </k>
requires COND =/=Int 0

rule <k> break ~> #for COND END BODY => .K ... </k>
rule <k> break ~> ST:Stmt => break ... </k> [owise]

rule <k> continue ~> INNER ~> #for COND END BODY => #for COND END BODY ... </k>
rule <k> continue ~> #for COND END BODY ~> CONT => #for COND END BODY ~> CONT ... </k>


rule <k> ... ST STMTS:Stmts => ST ~> STMTS ... </k>
rule <k> ... .Stmts => .K ... </k>
```
### Variable handling

```k
syntax KItem ::= "#resetEnv" Set

rule <k> { B } => B ... </k>
//TODO: variable scoping
// rule <k> { B } => B ~> #resetEnv STORE ... </k>
//      <varStore> STORE </varStore>

rule <k> #resetEnv SCOPEDVARS => .K ... </k>
<varStore> STORE => removeAll(STORE, keys(STORE) -Set SCOPEDVARS) </varStore>

syntax Map ::= "#restore" Map Map


rule <k> let X := Y:Int => . ... </k>
     <varStore> VARS => VARS [X <- Y] </varStore>
     requires notBool X in_keys(VARS)

rule <k> let X => . ... </k>
     <varStore> VARS => VARS [X <- 0] </varStore>
     requires notBool X in_keys(VARS)

rule <k> X := Y:Int => . ... </k>
     <varStore> VARS => VARS [X <- Y] </varStore>
     requires X in_keys(VARS)

rule <k> X:Id => VAL ... </k>
     <varStore> (X |-> VAL) M </varStore>

```
### Storage operations

```k
rule <k> sstore(X:Int, Y:Int) => . ... </k>
<storage> M:Map => M [X <- Y] </storage>

rule <k> sload(X:Int) => Y ... </k>
<storage> (X |-> Y) M:Map </storage>
```



### Arithmetic

```k
    syntax Int ::= Int "+Word"  Int  [function]
                 | Int "*Word"  Int  [function]
                 | Int "-Word"  Int  [function]
                 | Int "/Word"  Int  [function]
                 | Int "%Word"  Int  [function]
                 | Int "<Word"  Int  [function]
                 | Int ">Word"  Int  [function]
                 | Int "<=Word" Int  [function]
                 | Int ">=Word" Int  [function]
                 | Int "==Word" Int  [function]
                 |     "~Word"  Int  [function]
                 | Int "|Word"   Int [function]
                 | Int "&Word"   Int [function]
                 | Int "xorWord" Int [function]
                 | Int "<<Word"  Int [function]
                 | Int ">>Word"  Int [function]
                 | Int ">>sWord" Int [function]
 // -------------------------------------------
    rule W0 +Word W1   => W0 +Int W1 modInt pow256
    rule W0 -Word W1   => W0 -Int W1 modInt pow256
    rule W0 *Word W1   => W0 *Int W1 modInt pow256
    rule W0 /Word W1   => 0            requires W1  ==Int 0
    rule W0 /Word W1   => W0 /Int W1   requires W1 =/=Int 0
    rule W0 %Word W1   => 0            requires W1  ==Int 0
    rule W0 %Word W1   => W0 modInt W1 requires W1 =/=Int 0
    rule W0 <Word  W1  => bool2Word(W0 <Int  W1)
    rule W0 >Word  W1  => bool2Word(W0 >Int  W1)
    rule W0 <=Word W1  => bool2Word(W0 <=Int W1)
    rule W0 >=Word W1  => bool2Word(W0 >=Int W1)
    rule W0 ==Word W1  => bool2Word(W0 ==Int W1)
    rule     ~Word W   => W xorInt pow256
    rule W0 |Word   W1 => W0 |Int W1
    rule W0 &Word   W1 => W0 &Int W1
    rule W0 xorWord W1 => W0 xorInt W1
    rule W0 <<Word  W1 => W0 <<Int W1 modInt pow256 requires W1 <Int 256
    rule W0 <<Word  W1 => 0 requires W1 >=Int 256
    rule W0 >>Word  W1 => W0 >>Int W1
//    rule W0 >>sWord W1 => chop( (abs(W0) *Int sgn(W0)) >>Int W1 )

    syntax Int ::= bool2Word ( Bool ) [function]
 // --------------------------------------------
    rule bool2Word( B:Bool ) => 1 requires B
    rule bool2Word( B:Bool ) => 0 requires notBool B

rule <k> add(X, Y)  => X +Word Y ... </k>
rule <k> sub(X, Y)  => X -Word Y ... </k>
rule <k> mul(X, Y)  => X *Word Y ... </k>
rule <k> divu(X, Y) => X /Word Y ... </k>
//TODO: signed operators
//rule <k> divs(X, Y) =>
rule <k> mod(X, Y)  => X %Word Y ... </k>
rule <k> lt(X, Y)   => X <Word Y ... </k>
rule <k> gt(X, Y)   => X >Word Y ... </k>
rule <k> iszero(X)  => bool2Word(X ==Int 0) ... </k>
rule <k> or(X, Y)   => X |Word Y ... </k>
rule <k> xor(X, Y)  => X xorWord Y ... </k>
rule <k> and(X, Y)  => X &Word Y ... </k>
```

### Memory
```k
rule <k> mstore(X, Y) => . ... </k>
     <memory> MEM => MEM [X := padLeftBytes(Int2Bytes(Y, BE, Unsigned), 32, 0)] </memory>

rule <k> mload(X) => Bytes2Int(#range(MEM, X, 32), BE, Unsigned) ... </k>
<memory> MEM </memory>

syntax Bytes ::= #range ( Map , Int , Int )                 [function]
               | #range ( Map , Int , Int , Int , Bytes )   [function, klabel(#rangeAux)]
//---------------------------------------------------------------------------------------
rule #range(WM, START, WIDTH) => #range(WM, START, 0, WIDTH, padLeftBytes(.Bytes, WIDTH, 0))
rule #range(WM, I, WIDTH, WIDTH, WS) => WS
rule #range(WM, I,     J, WIDTH, WS) => #range(WM, I +Int 1, J +Int 1, WIDTH, WS [ J <- {WM[I] orDefault 0}:>Int ]) [owise]

endmodule
```
