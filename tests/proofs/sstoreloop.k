requires "main.k"
module SYNC-POINTS
imports YUL


rule
<s> ~ a => ^ b ... </s>
<ak> #for C E B </ak>
[trusted]

rule
<s> ~ a => ^ b ... </s>
<ak> .K </ak>
[trusted]

rule
<s> ~ b => ^ a ... </s>
<bk> #for C E B </bk>
[trusted]

rule
<s> ~ b => ^ a ... </s>
<bk> .K </bk>
[trusted]

endmodule

module SSTORELOOP
imports YUL
imports YUL-SYNTAX
imports SYNC-POINTS

rule
<c>
<k> .K </k>
<s> ^ a </s>
<ayul>
  <ak>
  {
      let _1 := 20
      sstore(0, _1)
      let x := 0
      let y := x  
      for { } 1 { x := add(x, 1) }
      {
          if iszero(lt(x, _1)) { break }
          y := add(x, y)
      }
      sstore(1,y)
   }
    => _
   </ak>
   <avarStore> .Map </avarStore>
   <astorage> .Map </astorage> //TODO: multiple accounts
   <acallState>
      <amemory> .Map </amemory> //TODO: just Bytes instead?
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
  sstore(0, 20)
  let y
  for {let x := 0} lt(x, sload(0)) {x := add(x, 1)} {
     y := add(x, y)
  }
  sstore(1,y)
} => _
</bk>
 <bvarStore> .Map </bvarStore>
 <bstorage> .Map </bstorage> //TODO: multiple accounts
 <bcallState>
     <bmemory> .Map </bmemory> //TODO: just Bytes instead?
     <bcallDepth> 0      </bcallDepth>
     <bacct>      0      </bacct>      // I_a
     <bcaller>    0      </bcaller>    // I_s
     <bcallData>  .Bytes </bcallData>  // I_d
     <bcallValue> 0      </bcallValue> // I_v
     <bgas>       0      </bgas>       // \mu_g
 </bcallState>
 </byul>
</c>

endmodule