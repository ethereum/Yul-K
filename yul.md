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


syntax Object ::= "object" String "{" Code "}"
                | "object" String "{" Code Chunk "}"

syntax Chunk ::= Object | Data | Code

syntax Code ::= "code" Block

syntax Data ::= "data" Id Hex
              | "data" Id String

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

syntax VariableDeclaration ::= "let" Id ":=" Expr

syntax Assignment ::= Id ":=" Expr

syntax Expr ::= FunctionCall | Id | Literal

syntax Exprs ::=  List{Expr, ","} [klabel(listId)]

syntax Cond ::= "if" Expr Block

syntax Switch ::= "switch" Expr Cases

syntax Cases ::= List{Case, ""} [klabel(listCase)]

syntax Case ::= "case" Literal Block
             |  "default" Block

syntax ForLoop ::= "for" Block Expr Block Block

syntax BreakContinue ::= "break" | "continue"

syntax FunctionCall ::= Id "(" Exprs ")"
                      | Id "()"
                      | Instr

syntax Literal ::= Int | String | Hex | Bool

syntax Hex ::= r"[\\+-]?0x[0-9a-fA-F]*" [token]

syntax Instr ::= "not"           "(" Expr                   ")"
               | "and"           "(" Expr "," Expr          ")"
               | "or"            "(" Expr "," Expr          ")"
               | "xor"           "(" Expr "," Expr          ")"
               | "add"           "(" Expr "," Expr          ")"
               | "sub"           "(" Expr "," Expr          ")"
               | "mul"           "(" Expr "," Expr          ")"
               | "divu"          "(" Expr "," Expr          ")"
               | "divs"          "(" Expr "," Expr          ")"
               | "mod"           "(" Expr "," Expr          ")"
               | "mstore"        "(" Expr "," Expr          ")"
               | "mstore8"       "(" Expr "," Expr          ")"
               | "sstore"        "(" Expr "," Expr          ")"
               | "return"        "(" Expr "," Expr          ")"
               | "revert"        "(" Expr "," Expr          ")"
               | "mload"         "(" Expr                   ")"
               | "calldatacopy"  "(" Expr "," Expr "," Expr ")"
               | "datacopy"      "(" Expr "," Expr "," Expr ")"
               | "sload"         "(" Expr                   ")"
               | "lt"            "(" Expr "," Expr          ")"
               | "gt"            "(" Expr "," Expr          ")"
               | "keccak256"     "(" Expr "," Expr          ")"
               | "iszero"        "(" Expr                   ")"
               | "codecopy"      "(" Expr "," Expr "," Expr ")"
               | "datasize" "(" String ")"
               | "dataoffset" "(" String ")"
               | "msize"         "()"
               | "calldatasize"  "()"
               | "call" "(" Expr "," Expr "," Expr "," Expr "," Expr "," Expr "," Expr ")"
               | "delegatecall" "(" Expr "," Expr "," Expr "," Expr "," Expr "," Expr ")"
               //But wait! There's more!

endmodule
```
