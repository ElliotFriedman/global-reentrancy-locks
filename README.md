# Global Reentrancy Lock

The Global Reentrancy Lock provides a base class for implementing a reentrancy lock mechanism with multiple lock levels. The project is inspired by the OpenZeppelin reentrancy guard smart contracts. This readme will guide you through the project structure and help you understand how to use the base class in your own contracts.

## Table of Contents
- [Project Structure](#project-structure)
- [BaseGlobalReentrancyLock](#baseglobalreentrancylock)
- [GlobalReentrancyLock Example](#globalreentrancylock-example)
- [Usage](#usage)
- [Testing](#testing)

## Project Structure
The project consists of the following files:
- `BaseGlobalReentrancyLock.sol`: The base class implementing the reentrancy lock mechanism.
- `Constants.sol`: A file containing constant values used in the project.
- `GlobalReentrancyLock.sol`: An example contract inheriting from the base class.

## BaseGlobalReentrancyLock

The `BaseGlobalReentrancyLock` contract is the core of the project. It provides functions to lock and unlock the system at different levels. The contract enforces a set of invariants to ensure the system behaves correctly.

The storage variables of the contract are:
- `lastSender`: The address that locked the system. (160 bits)
- `lastBlockEntered`: The block number when the system was last locked. (88 bits)
- `lockLevel`: The current lock level of the system. (8 bits)

All of these variables are packed into a single slot to optimize gas usage and prevent multiple cold SSTORE operations per transaction.

The immutable variable in this contract is:
- `maxLockLevel`: The maximum lock level allowed by the system.

The primary internal functions of the contract are:
- `_lock(uint8 toLock)`: Locks the system at a specific level.
- `_unlock(uint8 toUnlock)`: Unlocks the system to a specific level.

These functions should be called by child contracts that inherit the `BaseGlobalReentrancyLock`.

BaseGlobalReentrancy lock contains many assert statements. All of these statements can be safely removed for production builds as their purpose is solely to assist symbolic tools in proving correctness of the program.

## GlobalReentrancyLock Example

`GlobalReentrancyLock.sol` is an example contract that inherits from the `BaseGlobalReentrancyLock` base class. It showcases how to use the base class in a practical implementation. The example contract provides functions to lock and unlock the system, as well as view functions to check if the system is locked or unlocked.

**Note**: The example contract does not include any access controls, so it should not be used in production without implementing proper access control mechanisms.

## Usage

To use the `BaseGlobalReentrancyLock` in your own contracts, follow these steps:

1. Import the `BaseGlobalReentrancyLock.sol` file in your contract.
2. Inherit from the `BaseGlobalReentrancyLock` contract and set the `maxLockLevel` in the constructor.
3. Implement the necessary access control mechanisms in your contract.
4. Use the `_lock` and `_unlock` functions to control the lock state of your contract.

## Testing

When testing your implementation, make sure to cover the following scenarios:
- Locking and unlocking the system at different levels.
- Invalid state transitions.
- Testing with proper access control mechanisms.

Keep in mind that the provided `GlobalReentrancyLock.sol` example contract is not suitable for production use as it lacks access controls.
