Yul
===

### Overview

Intermediate blockchain language

This module contains syntax and rules for K productions that are `[function]`s.
```k
module YUL-SYNTAX
  imports ID
  imports BYTES
  imports INT
  imports STRING
  imports MAP
```
Syntax
------

Yul comments are given in javascript-style: 
Comment line with //
or multiline /* like this */ (TODO)

```k
syntax #Layout ::= r"\\/\\/[^\\n\\r]*" [token]
                 | r"[\\ \\n\\r\\t]"   [token]
// -------------------------------------------


syntax Object ::= "object" String "{" Code Chunks "}"

syntax Chunk ::= Object | Data | Code

syntax Chunks ::= List{Chunk, "\n"} [klabel(listChunk)]

syntax Code ::= "code" Block

syntax Data ::= "data" String HexLiteral
              | "data" String String

syntax Block ::= "{" Stmts "}"

syntax Stmts ::= List{Stmt, ""}

syntax Stmt ::= Block
             | FunctionDefinition
             | VariableDeclaration
             | Assignment
             | Cond
             | Expr
             | Switch
             | ForLoop
             | BreakContinue

//TODO: Types? (Doesn't seem to be supported right now, but may be in the future
syntax Ids ::= Id | Id "," Ids

syntax FunctionDefinition ::= "function" Id"("Ids")" Block
                            | "function" Id"("Ids")" "->" Ids Block
                            | "function" Id"()"
                            | "function" Id"()" "->" Ids Block

syntax VariableDeclaration ::= "let" Ids ":=" Expr //[strict(2)]
                             | "let" Ids

syntax Assignment ::= Ids ":=" Expr //[strict(2)]

syntax Expr ::= FunctionCall | Id | Literal

syntax Exprs ::=  List{Expr, ","} [klabel(listId)]

syntax Cond ::= "if" Expr Block// [strict(1)]

syntax Switch ::= "switch" Expr Cases

syntax Cases ::= List{Case, ""} [klabel(listCase)]

syntax Case ::= "case" Literal Block
             |  "default" Block

syntax ForLoop ::= "for" Block Expr Block Block

syntax Stmt ::= "#for" Expr Block Block

syntax BreakContinue ::= "break" | "continue"

syntax FunctionCall ::= Id "(" Exprs ")"
                      | Id "()"
                      | Instr

syntax Literal ::= Int | String | HexNumber | Bool

syntax HexLiteral ::= "hex" String

//syntax HexNumber ::= "0x" String

syntax KResult ::= Int

//TODO: can this be a function?
syntax HexNumber ::= r"0x[0-9a-fA-F]*" [token]

syntax Instr ::= "not"           "(" Expr                   ")" [strict]
               | "and"           "(" Expr "," Expr          ")" //[strict]
               | "or"            "(" Expr "," Expr          ")" [strict]
               | "xor"           "(" Expr "," Expr          ")" [strict]
               | "add"           "(" Expr "," Expr          ")" [strict]
               | "sub"           "(" Expr "," Expr          ")" [strict]
               | "mul"           "(" Expr "," Expr          ")" [strict] 
               | "divu"          "(" Expr "," Expr          ")" [strict]
               | "divs"          "(" Expr "," Expr          ")" [strict]
               | "mod"           "(" Expr "," Expr          ")" [strict]
               | "mstore"        "(" Expr "," Expr          ")" [strict]
               | "mstore8"       "(" Expr "," Expr          ")" [strict]
               | "sstore"        "(" Expr "," Expr          ")" //[strict]
               | "return"        "(" Expr "," Expr          ")" [strict]
               | "revert"        "(" Expr "," Expr          ")" [strict]
               | "mload"         "(" Expr                   ")" [strict]
               | "calldatacopy"  "(" Expr "," Expr "," Expr ")" [strict]
               | "datacopy"      "(" Expr "," Expr "," Expr ")" [strict]
               | "sload"         "(" Expr                   ")" [strict]
               | "lt"            "(" Expr "," Expr          ")" //[strict]
               | "gt"            "(" Expr "," Expr          ")" [strict]
               | "keccak256"     "(" Expr "," Expr          ")" [strict]
               | "iszero"        "(" Expr                   ")" //[strict]
               | "codecopy"      "(" Expr "," Expr "," Expr ")" [strict]
               | "datasize" "(" String ")"
               | "dataoffset" "(" String ")"
               | "msize"         "()"
               | "calldatasize"  "()"
               | "call" "(" Expr "," Expr "," Expr "," Expr "," Expr "," Expr "," Expr ")"
               | "delegatecall" "(" Expr "," Expr "," Expr "," Expr "," Expr "," Expr ")"
               //But wait! There's more!

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
    rule W0 -Word W1   => W0 -Int W1 requires W0 >=Int W1
    rule W0 -Word W1   => W0 +Int pow256 -Int W1 modInt pow256 requires W0 <Int W1
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

    syntax Int ::= bool2Word ( Bool ) [function]
 // --------------------------------------------
    rule bool2Word( B:Bool ) => 1 requires B
    rule bool2Word( B:Bool ) => 0 requires notBool B

syntax Int ::= "pow256" /* 2 ^Int 256 */

rule pow256 => 115792089237316195423570985008687907853269984665640564039457584007913129639936 [macro]
```
The following constructs are declared in a separate module to avoid some parsing problems in the java backend
```k
    syntax Stmt ::= "#resetEnv" Map

    syntax String  ::= #parseHexString   ( HexNumber ) [function, functional, hook(STRING.token2string)]
    syntax Int ::= #parseHexWord ( String ) [function]
 // ----------------------------------------------------
    rule #parseHexWord("")   => 0
    rule #parseHexWord("0x") => 0
    rule #parseHexWord(S)    => String2Base(replaceAll(S, "0x", ""), 16) requires (S =/=String "") andBool (S =/=String "0x")


syntax Bytes ::= #range ( Map , Int , Int )         [function]
               | #range ( Map , Int , Int , Bytes ) [function, klabel(#rangeAux)]
//---------------------------------------------------------------------------------------
    rule #range(WM, START, WIDTH) => #range(WM, START +Int WIDTH -Int 1, WIDTH, .Bytes)

    rule #range(WM,           END, WIDTH, WS) => WS                                                requires WIDTH ==Int 0
    rule #range(WM,           END, WIDTH, WS) => #range(WM, END -Int 1, WIDTH -Int 1, Int2Bytes(0, BE, Unsigned) +Bytes WS)
    requires (WIDTH >Int 0) andBool notBool END in_keys(WM)
    rule #range(END |-> W WM, END, WIDTH, WS) => #range(WM, END -Int 1, WIDTH -Int 1, Int2Bytes(W, BE, Unsigned) +Bytes WS) requires (WIDTH >Int 0)

syntax Map ::= Map "[" Int ":=" Bytes "]" [function, klabel(mapWriteBytes)]
// ------------------------------------------------------------------------
rule WM[ N := WS ] => WM [ N := WS, 0, lengthBytes(WS) ]

syntax Map ::= Map "[" Int ":=" Bytes "," Int "," Int "]" [function]
// -----------------------------------------------------------------
rule WM [ N := WS, I, I ] => WM
rule WM [ N := WS, I, J ] => (WM[N <- WS[I]]) [ N +Int 1 := WS, I +Int 1, J ] requires I <Int J


syntax KItem ::= Block
```

K's program equivalence checker does not currently support productions with a `[strict]` attribute. Instead, we need to manually define heating and cooling rules for such productions.

For now, let's only do the minimal fragment needed to support `tests/simple/loopunoptimized` and `tests/simple/loopoptimized`.
```k
syntax KItem ::= #addi1(K)    | #addi2(K)
               | #sstorei1(K) | #sstorei2(K)
               | "#iszeroi"
               | #lti1(K)     | #lti2(K)
               | #ifi(K)
               | #leti(K)     | #assign(K)
endmodule
```
