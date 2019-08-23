//
//@title MultiSignatureWallet
//@author Nick Dodson <thenickdodson@gmail.com>
//@notice 311 byte EIP712 Signing Compliant Delegate-Call Enabled MultiSignature Wallet for the Ethereum Virtual Machine
//
object "MultiSignatureWallet" {
  code {
    // constructor: uint256(signatures required) + address[] signatories (bytes32 sep|chunks|data...)
    sstore(address(), mload(0)) // map contract address => signatures required

    for { let i := 96 } lt(i, add(96, mul(32, mload(64)))) { i := add(i, 32) } { // iterate through signatory addresses
       sstore(mload(i), mload(i)) // map signer address => signer address
    }

    datacopy(0, dataoffset("Runtime"), datasize("Runtime")) // now switch over to runtime code from constructor
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
      if calldatasize() { // call data: bytes4(sig) bytes32(dest) bytes32(gasLimit) bytes(data) bytes32[](signatures) | supports fallback
        calldatacopy(1060, 0, calldatasize()) // copy calldata to memory

        let dataLength := mload(1192) // size of the bytes data

        // build EIP712 release hash
        mstore(1000, 0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6) // EIP712 Execute TypeHash: Execute(uint256 nonce,address destination,uint256 gasLimit,bytes data)
        mstore(1032, sload(add(address(), 1))) // map wallet nonce to memory (nonce: storage(address + 1))
        mstore(1128, keccak256(1224, dataLength)) // we have to hash the bytes data due to EIP712... why....

        mstore8(0, 0x19) // EIP712 0x1901 prefix
        mstore8(1, 0x01)
        mstore(2, 0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2) // EIP712 Domain Seperator: EIP712Domain(string name,string version,uint256 chainId)
        mstore(34, keccak256(1000, 160)) // EIP712 Execute() Type Hash

        let EIP712Hash := keccak256(0, 66) // EIP712 final signing hash
        let previousAddress := 0 // comparison variable, used to check for duplicate signer accounts

        for { let i := 0 } lt(i, sload(address())) { i := add(i, 1) } { // signature validation: loop through signatures (i < required signatures)
            let memPosition := add(add(1064, mload(1160)), mul(i, 96)) // new memory position -32 bytes from sig start

            mstore(memPosition, EIP712Hash) // place hash before each sig in memory: hash + v + r + s | hash + vN + rN + sN

            let result := call(3000, 1, 0, memPosition, 128, 300, 32) // call ecrecover precompile with ecrecover(hash,v,r,s) | failing is okay here

            if iszero(gt(sload(mload(300)), previousAddress)) { revert(0, 0) } // sload(current address) > prev address OR revert

            previousAddress := mload(300) // set previous address for future comparison
        }

        sstore(add(address(), 1), add(1, mload(1032))) // increase nonce: nonce = nonce + 1

        if iszero(delegatecall(mload(1096), mload(1064), 1224, dataLength, 0, 0)) { revert (0, 0) } // make delegate call, revert on fail
      }
    }
  }
}
