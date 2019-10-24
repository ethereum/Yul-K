requires "main.k"
module SYNCPOINTS
imports MAIN

rule
<s> ~ a => ^ b ... </s>
<ak> #for C (B) ... </ak>
[trusted]

rule
<s> ~ a => ^ b ... </s>
<ak> .K </ak>
<acontrol> .K </acontrol>
[trusted]

rule
<s> ~ b => ^ a ... </s>
<bk> #for C (B) ... </bk>
[trusted]

rule
<s> ~ b => ^ a ... </s>
<bk> .K </bk>
<bcontrol> .K </bcontrol>
[trusted]

endmodule

module SSTORELOOP-SPEC
imports MAIN
imports SYNCPOINTS

syntax Id ::= "_1" [token]
            | "x" [token]
            | "y" [token]

rule
<c>
<k> check => . </k>
<s> ^ a </s>
<ayul>
  <ak>
  {
      let _1 := 4
      sstore(0, _1)
      let x := 0
      let y := x  
      for { .Stmts } 1 { x := add(x, 1) }
      {
          if iszero(lt(x, _1)) { break }
          y := add(y, x)
      }
      sstore(1,y)
   }
    => _
   </ak>
   <avars> .Map => _ </avars>
   <afuncs> .Map => _ </afuncs>
   <aenvStack> .List => _ </aenvStack>
   <acontrol> .K => _ </acontrol>
   <astorage> .Map => _ </astorage> 
   <acallState>
      <amemory> .Map => _ </amemory>
      <acallDepth> 0      </acallDepth>
      <aacct>      0      </aacct>      // I_a
      <acaller>    0      </acaller>    // I_s
      <acallData>  .Bytes </acallData>  // I_d
      <acallValue> 0      </acallValue> // I_v
      <agas>       0      </agas>       // \mu_g
   </acallState>
</ayul>
<byul>
<bk>
{
  sstore(0, 4)
  let y
  for {let x := 0} lt(x, sload(0)) {x := add(x, 1)} {
     y := add(y, x)
  }
  sstore(1,y)
} => _
</bk>
 <bvars> .Map => _ </bvars>
 <bfuncs> .Map => _ </bfuncs>
 <benvStack> .List => _ </benvStack>
 <bcontrol> .K => _ </bcontrol>
 <bstorage> .Map => _ </bstorage> //TODO: multiple accounts
 <bcallState>
     <bmemory> .Map => _ </bmemory> //TODO: just Bytes instead?
     <bcallDepth> 0      </bcallDepth>
     <bacct>      0      </bacct>      // I_a
     <bcaller>    0      </bcaller>    // I_s
     <bcallData>  .Bytes </bcallData>  // I_d
     <bcallValue> 0      </bcallValue> // I_v
     <bgas>       0      </bgas>       // \mu_g
 </bcallState>
 </byul>
</c>

rule
<c>
<k> check => . </k>
<s> ^ a </s>
<ayul>
  <ak> .K
   </ak>
   <avars> _ => _ </avars>
   <afuncs> _ => _ </afuncs>
   <aenvStack> .List => _ </aenvStack>
   <acontrol> .K => _ </acontrol>
   <astorage> AMAP => _ </astorage> //TODO: multiple accounts
   <acallState>
      <amemory> _ </amemory> //TODO: just Bytes instead?
      <acallDepth> 0      </acallDepth>
      <aacct>      0      </aacct>      // I_a
      <acaller>    0      </acaller>    // I_s
      <acallData>  .Bytes </acallData>  // I_d
      <acallValue> 0      </acallValue> // I_v
      <agas>       0      </agas>       // \mu_g
   </acallState>
</ayul>
<byul>
<bk> .K
</bk>
 <bvars> _ => _ </bvars>
 <bfuncs> _ => _ </bfuncs>
 <benvStack> .List => _ </benvStack>
 <bcontrol> .K => _ </bcontrol>
 <bstorage> BMap => _ </bstorage> //TODO: multiple accounts
 <bcallState>
     <bmemory> _ => _ </bmemory> //TODO: just Bytes instead?
     <bcallDepth> 0      </bcallDepth>
     <bacct>      0      </bacct>      // I_a
     <bcaller>    0      </bcaller>    // I_s
     <bcallData>  .Bytes </bcallData>  // I_d
     <bcallValue> 0      </bcallValue> // I_v
     <bgas>       0      </bgas>       // \mu_g
 </bcallState>
 </byul>
</c>
requires AMap ==K BMap
[trusted]

rule
<c>
<k> check => . </k>
<s> ^ a </s>
<ayul>
  <ak>
      #for 1 (
          if iszero(lt(x, _1)) { break }
          y := add(y, x)
          x := add(x, 1)
          ) ~> #popEnv
       => _
   </ak>
   <avars>
      _1 |-> ONE:Int
      x |-> X:Int
      y |-> Y:Int
   => _ </avars>
   <afuncs> _ => _ </afuncs>
   <aenvStack> _ => _ </aenvStack>
   <acontrol> sstore(1,y) ~> #popEnv => _ </acontrol>
   <astorage> 0 |-> ONE
   => _ </astorage>
   <acallState>
      <amemory> _ => _ </amemory>
      <acallDepth> 0      </acallDepth>
      <aacct>      0      </aacct>      // I_a
      <acaller>    0      </acaller>    // I_s
      <acallData>  .Bytes </acallData>  // I_d
      <acallValue> 0      </acallValue> // I_v
      <agas>       0      </agas>       // \mu_g
   </acallState>
</ayul>
<byul>
<bk>
#for lt(x, sload(0)) (
     y := add(y, x)
     x := add(x, 1)
     ) ~> #popEnv
 => _
 </bk>
 <bvars> x |-> X:Int
         y |-> Y:Int
 => _ </bvars>
 <bfuncs> _ => _ </bfuncs>
 <bcontrol> sstore(1,y) ~> #popEnv => _ </bcontrol>
 <benvStack> _ => _ </benvStack>
 <bstorage> 0 |-> ONE => _ </bstorage>
 <bcallState>
     <bmemory> _ => _ </bmemory>
     <bcallDepth> 0      </bcallDepth>
     <bacct>      0      </bacct>      // I_a
     <bcaller>    0      </bcaller>    // I_s
     <bcallData>  .Bytes </bcallData>  // I_d
     <bcallValue> 0      </bcallValue> // I_v
     <bgas>       0      </bgas>       // \mu_g
 </bcallState>
 </byul>
</c>
requires X <=Int ONE
 andBool ONE <=Int 100000
// [trusted]

endmodule