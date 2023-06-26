// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {BaseGlobalReentrancyLock} from "./../BaseGlobalReentrancyLock.sol";

/// @notice example implementation of the global reentrancy lock contract
/// not for production use, just an example contract.
contract ExampleGlobalReentrancyLock is BaseGlobalReentrancyLock, AccessControlEnumerable {

    /// @notice responsible for granting and revoking locker role
    bytes32 public constant governor = keccak256("GOVERNOR");

    /// @notice responsible for managing the reentrancy lock state
    bytes32 public constant locker = keccak256("LOCKER");

    /// @notice emitted when governor makes use of emergency unlock
    event EmergencyUnlock();

    /// @param _maxLockLevel maximum lock level of global reentrancy lock
    constructor (uint8 _maxLockLevel) BaseGlobalReentrancyLock(_maxLockLevel) {
        _grantRole(governor, msg.sender); /// sender is governor
        _grantRole(locker, msg.sender); /// sender is locker
        _setRoleAdmin(locker, governor); /// governor is admin of locker
    }

    /// @notice lock the system to the specified level
    /// @param toLock level to set system lock to
    function lock(uint8 toLock) external onlyRole(locker) {
        _lock(toLock);
    }

    /// @notice unlock the system to the specified level
    /// @param toUnlock level to set system lock to
    function unlock(uint8 toUnlock) external onlyRole(locker) {
        _unlock(toUnlock);
    }

    /// @notice emergency function that can be called only by governor if 
    /// the contracts are locked, and have not been unlocked
    function governorEmergencyUnlock() external onlyRole(governor) {
        require(block.number != lastBlockEntered, "ExampleGlobalReentrancyLock: governor cannot unlock");
        lockLevel = 0; /// set lock level to 0

        emit EmergencyUnlock();
    }
}
