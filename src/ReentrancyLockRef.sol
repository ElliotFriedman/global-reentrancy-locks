pragma solidity 0.8.20;

import {GlobalReentrancyLock} from "@protocol/example/GlobalReentrancyLock.sol";

/// @notice reference to the global reentrancy lock
/// allows parent contracts to set the lock using their own logic
contract ReentrancyLockRef {

    /// @notice reference to the lock
    GlobalReentrancyLock public lock;

    /// @notice emitted when the lock is updated
    event GlobalReentrancyLockUpdated(address indexed oldLock, address indexed newLock);

    /// @notice construct the contract and set the lock
    /// @param _lock the lock to set
    constructor(GlobalReentrancyLock _lock) {
        lock = _lock;
    }

    /// @notice global reentrancy lock modifier
    /// @param toLock the lock level to lock to
    modifier globalLock(uint8 toLock) {
        lock.lock(toLock);
        _;
        lock.unlock(toLock - 1);
    }

    /// @notice set the lock to a new lock
    /// @param _lock the new lock
    function _setLock(GlobalReentrancyLock _lock) internal {
        lock = _lock;
    }
}
