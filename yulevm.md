Imports EEI semantics for now

```k
//requires "domains.k"
requires "eei.k"
//requires "data.k" //of evm-semantics
requires "yul.k"
module YULEVM
imports YUL-SYNTAX
//imports INT
imports EEI
//imports EVM-DATA

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

syntax KItem ::= Block

syntax KItem ::= "#for" Expr Block Block

rule <k> for BEGIN COND END BODY => BEGIN ~> #for COND END BODY ... </k>

rule <k> #for COND END BODY => BODY ~> END ~> #for COND END BODY ... </k>
requires COND =/=K 0

rule <k> #for COND END BODY => . ... </k>
requires COND ==K 0
```
### Variable handling

```k
syntax KItem ::= "#put" Id
               | "#get" Id

rule <k> let X := Y => Y ~> #put X ... </k>
     <varStore> VARS </varStore>
     requires notBool X in_keys(VARS)

rule <k> X := Y => Y ~> #put X ... </k>
     <varStore> VARS </varStore>
     requires X in_keys(VARS)

rule <k> Y ~> #put X ... </k>
     <varStore> VARS => VARS [X <- Y] </varStore>
     requires notBool X in_keys(VARS)

rule <k> #get X => VAL ... </k>
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
syntax KItem ::= "#mstore"

rule <k> mstore(X, Y) => X ~> Y ~> #mstore ... </k>

rule <k> X ~> Y ~> #mstore => . ... </k>
     <memory> MEM => MEM [X := padLeftBytes(Int2Bytes(Y, BE, Unsigned), 32, 0)] </memory>

endmodule
```
