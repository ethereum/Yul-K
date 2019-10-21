# yul-semantics

K formalization of the [Yul language](https://solidity.readthedocs.io/en/v0.5.11/yul.html)

Requires the same dependencies as [evm-semantics](https://github.com/kframework/evm-semantics#system-dependencies)

Build with:

```sh
make
```


The main goal of this repository is to verify optimizations done by the Solidity compiler via _translation validation_. In other words, given a yul program, `A` and the optimized version, `A'`, we prove the an equivalence of programs `A <=> A'` through bisimulation.

Try the example `tests/proofs/sstoreloop-spec.k` by running:
```sh
./kyul prove tests/proofs/sstoreloop-spec.k
```

If you want to explore the proof, run:
```sh
./kyul klab-prove tests/proofs/sstoreloop-spec.k
```
followed by:
```sh
./kyul klab-view tests/proofs/sstoreloop-spec.k
```
