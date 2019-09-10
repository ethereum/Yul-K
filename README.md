# yul-semantics

K formalization of the [Yul language](https://solidity.readthedocs.io/en/v0.5.11/yul.html)

Requires the same dependencies as [evm-semantics](https://github.com/kframework/evm-semantics#system-dependencies)

Build with:

```
make
```

Aim is to verify solidity compiler optimization steps.

Currently running some basic examples. Try for example `./kyulrun tests/simple/loopunoptimized.yul`

