
```k
requires "yul-syntax.k"
requires "yulevm-a.k"
requires "yulevm-b.k"
module YUL
imports YULEVM-A
imports YULEVM-B
imports YUL-SYNTAX

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

endmodule
```
