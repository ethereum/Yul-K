Imports EEI semantics for now

```k
requires "eei.k"
requires "yul.k"
module YULEVM
imports YUL-SYNTAX
imports EEI

configuration
      <yul>
         <k> $PGM </k>
         <memory> .Map </memory>
         <varStore> .Map </varStore>
        <eei/>
      </yul>

```

### Control flow

```k
syntax Stmt ::= "#for" Expr Block Block
               | "#freezerIf" Block

rule <k> for { STMTS } COND END BODY => STMTS ~> #for COND END BODY ~> #resetEnv STORE ... </k>
     <varStore> STORE </varStore>

rule <k> #for COND { END } { BODY } => COND ~> #freezerIf { END BODY #for COND {END} {BODY} } ... </k> [structural]

rule <k> COND ~> #freezerIf BODY => . ... </k>
requires COND ==Int 0

rule <k> COND ~> #freezerIf { BODY } => BODY ... </k>
requires COND =/=Int 0

rule <k> ST STMTS:Stmts => ST ~> STMTS ... </k> [structural]
rule <k> .Stmts => . ... </k> [structural]
```
### Variable handling

```k
syntax KItem ::= "#resetEnv" Map

rule <k> { B } => B ~> #resetEnv STORE ... </k>
     <varStore> STORE </varStore>

rule <k> #resetEnv STORE => . ... </k>
     <varStore> _ => STORE </varStore>

rule <k> let X := Y => . ... </k>
     <varStore> VARS => VARS [X <- Y] </varStore>
     requires notBool X in_keys(VARS)

rule <k> X := Y => . ... </k>
     <varStore> VARS => VARS [X <- Y] </varStore>
     requires X in_keys(VARS)

rule <k> X:Id => VAL ... </k>
     <varStore> (X |-> VAL) M </varStore>

```

### Arithmetic

```k
    syntax Int ::= Int "+Word"  Int [function]
                 | Int "*Word"  Int [function]
                 | Int "-Word"  Int [function]
                 | Int "/Word"  Int [function]
                 | Int "%Word"  Int [function]
                 | Int "<Word"  Int [function]
                 | Int ">Word"  Int [function]
                 | Int "<=Word" Int [function]
                 | Int ">=Word" Int [function]
                 | Int "==Word" Int [function]
 // ------------------------------------------
    rule W0 +Word W1 => W0 +Int W1 modInt pow256
    rule W0 -Word W1 => W0 -Int W1 modInt pow256
    rule W0 *Word W1 => W0 *Int W1 modInt pow256
    rule W0 /Word W1 => 0            requires W1  ==Int 0
    rule W0 /Word W1 => W0 /Int W1   requires W1 =/=Int 0
    rule W0 %Word W1 => 0            requires W1  ==Int 0
    rule W0 %Word W1 => W0 modInt W1 requires W1 =/=Int 0
    rule W0 <Word  W1 => bool2Word(W0 <Int  W1)
    rule W0 >Word  W1 => bool2Word(W0 >Int  W1)
    rule W0 <=Word W1 => bool2Word(W0 <=Int W1)
    rule W0 >=Word W1 => bool2Word(W0 >=Int W1)
    rule W0 ==Word W1 => bool2Word(W0 ==Int W1)
    syntax Int ::= bool2Word ( Bool ) [function]
 // --------------------------------------------
    rule bool2Word( B:Bool ) => 1 requires B
    rule bool2Word( B:Bool ) => 0 requires notBool B

rule <k> add(X, Y) => X +Word Y ... </k>
rule <k> mul(X, Y) => X *Word Y ... </k>
rule <k> lt(X, Y)  => X <Word Y ... </k>

```


### Memory
```k
rule <k> mstore(X, Y) => . ... </k>
     <memory> MEM => MEM [X := padLeftBytes(Int2Bytes(Y, BE, Unsigned), 32, 0)] </memory>

endmodule
```
