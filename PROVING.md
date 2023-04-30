# Proving the Global Reentrancy Lock

This document provides evidence that the Global Reentrancy Lock smart contract functions as intended, based on test results from various tools, including HEVM, Echidna, and Forge Invariants.

## Getting Started

### Symbolic Execution with HEVM

To prove the Global Reentrancy Lock with HEVM, first create the runtime binary using the solc compiler:

```bash
solc --bin-runtime src/example/GlobalReentrancyLock.sol 
```

The runtime binary can be found in the file `grl.bin-runtime`.

Next, run HEVM against this bytecode to check for any assertion violations:

```bash
hevm symbolic --code $(<grl.bin-runtime)
```

The output shows no assertion violations:

```
checking postcondition...
Q.E.D.
Explored: 83 branches without assertion violations
```

### Echidna

Echidna can be used to prove no assertion violations occur.

First, run the standard Echidna test suite against the contracts:

```bash
echidna test/invariants/echidna/EchidnaTest.sol --contract EchidnaTest --config test/invariants/echidna/config.echidna.yml
```

The output shows that all properties have passed:

```
Loaded total of 1 transactions from corpus/reproducers
Loaded total of 28 transactions from corpus/coverage
echidna_property_lock:  passed! 🎉
echidna_property:  passed! 🎉
```

Next, run the more complex assertions using the `config.echidna.assertions.yml` file:

```bash
echidna test/invariants/echidna/EchidnaTestConfig.sol --contract EchidnaTestConfig --config test/invariants/echidna/config.echidna.assertions.yml
```

The output shows that all properties have passed:

```
Loaded total of 1 transactions from corpus/reproducers
Loaded total of 19 transactions from corpus/coverage
echidna_property_sender:  passed! 🎉
echidna_property_last_entered:  passed! 🎉
echidna_property_lock:  passed! 🎉
echidna_property_single_block:  passed! 🎉
echidna_property:  passed! 🎉
Target contract is not self-destructed:  passed! 🎉
No contract can be self-destructed:  passed! 🎉
```

### Forge Invariants

Adding another layer of tests with Forge Invariants, the properties of the Global Reentrancy Lock can be further verified:

```bash
forge test --match-path './test/invariants/foundry/**' -vvv
```

The output shows no property violations:

```
Running 5 tests for test/invariants/foundry/GlobalReentrancyLock.t.sol:InvariantTestGlobalReentrancyLock
[PASS] invariant_CorrectLockLevel() (runs: 256, calls: 3840, reverts: 1429)
[PASS] invariant_Locked() (runs: 256, calls: 3840, reverts: 1429)
[PASS] invariant_LtMax() (runs: 256, calls: 3840, reverts: 1429)
[PASS] invariant_NotLockedAndUnlocked() (runs: 256, calls: 3840, reverts: 1429)
[PASS] invariant_SenderBlockCorrect() (runs: 256, calls: 3840, reverts: 1429)
Test result: ok. 5 passed; 0 failed; finished in 1.23s
```

## Conclusion

Based on the testing results from HEVM, Echidna, and Forge Invariants, it can be confidently asserted that the Global Reentrancy Lock smart contract functions as intended. No assertion violations or property violations were detected in any of the test runs. This provides strong evidence that the Global Reentrancy Lock invariants that were tested hold true.