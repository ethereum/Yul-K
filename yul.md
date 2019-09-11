Yul
===

### Overview

Intermediate blockchain language
```k
module YUL-SYNTAX
  imports ID
  imports INT
  imports STRING
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

syntax VariableDeclaration ::= "let" Ids ":=" Expr [strict(2)]
                             | "let" Ids

syntax Assignment ::= Ids ":=" Expr [strict(2)]

syntax Expr ::= FunctionCall | Id | Literal

syntax Exprs ::=  List{Expr, ","} [klabel(listId)]

syntax Cond ::= "if" Expr Block [strict(1)]

syntax Switch ::= "switch" Expr Cases

syntax Cases ::= List{Case, ""} [klabel(listCase)]

syntax Case ::= "case" Literal Block
             |  "default" Block

syntax ForLoop ::= "for" Block Expr Block Block

syntax BreakContinue ::= "break" | "continue"

syntax FunctionCall ::= Id "(" Exprs ")"
                      | Id "()"
                      | Instr

syntax Literal ::= Int | String | HexNumber | Bool

syntax HexLiteral ::= "hex" String

//syntax HexNumber ::= "0x" String

syntax KResult ::= Int

//TODO: How to convert this to int?
syntax HexNumber ::= r"0x[0-9a-fA-F]*" [token]

syntax Instr ::= "not"           "(" Expr                   ")" [strict]
               | "and"           "(" Expr "," Expr          ")" [strict]
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
               | "sstore"        "(" Expr "," Expr          ")" [strict]
               | "return"        "(" Expr "," Expr          ")" [strict]
               | "revert"        "(" Expr "," Expr          ")" [strict]
               | "mload"         "(" Expr                   ")" [strict]
               | "calldatacopy"  "(" Expr "," Expr "," Expr ")" [strict]
               | "datacopy"      "(" Expr "," Expr "," Expr ")" [strict]
               | "sload"         "(" Expr                   ")" [strict]
               | "lt"            "(" Expr "," Expr          ")" [strict]
               | "gt"            "(" Expr "," Expr          ")" [strict]
               | "keccak256"     "(" Expr "," Expr          ")" [strict]
               | "iszero"        "(" Expr                   ")" [strict]
               | "codecopy"      "(" Expr "," Expr "," Expr ")" [strict]
               | "datasize" "(" String ")"
               | "dataoffset" "(" String ")"
               | "msize"         "()"
               | "calldatasize"  "()"
               | "call" "(" Expr "," Expr "," Expr "," Expr "," Expr "," Expr "," Expr ")"
               | "delegatecall" "(" Expr "," Expr "," Expr "," Expr "," Expr "," Expr ")"
               //But wait! There's more!


//syntax Stmt ::= "#newAccount" Int

syntax Int ::= "pow256" /* 2 ^Int 256 */

rule pow256 => 115792089237316195423570985008687907853269984665640564039457584007913129639936 [macro]


    syntax String  ::= #parseHexString   ( HexNumber ) [function, functional, hook(STRING.token2string)]
    syntax Int ::= #parseHexWord ( String ) [function]
 // ----------------------------------------------------
    rule #parseHexWord("")   => 0
    rule #parseHexWord("0x") => 0
    rule #parseHexWord(S)    => String2Base(replaceAll(S, "0x", ""), 16) requires (S =/=String "") andBool (S =/=String "0x")

endmodule
```
