
```k
requires "yul-syntax.k"
requires "yulevm-a.k"
requires "yulevm-b.k"
module MAIN-SYNTAX
imports YUL-SYNTAX

endmodule

module MAIN

imports MAIN-SYNTAX
imports YULEVM-A
imports YULEVM-B

imports STRATEGY
imports RULE-TAG-SYNTAX

configuration
<c>
  <k> $PGM:Stmts </k>
  <s> ~ a </s>
  <ayul/>
  <byul/>
</c>

rule <s> ~ a => ^ a ... </s>

rule <s> ~ b => ^ b ... </s>

syntax String ::= RuleTag2String ( #RuleTag ) [function, hook(STRING.token2string)]

rule <s> ~ RT:#RuleTag => . ... </s>
requires RuleTag2String(RT) =/=String "a"
 andBool RuleTag2String(RT) =/=String "b"

syntax KItem ::= "check"

endmodule
```
