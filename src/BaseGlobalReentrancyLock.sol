// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Constants} from "./Constants.sol";

/// @notice Global reentrancy lock. Assert statements are for SMT solving
/// assertions only and can be removed for production builds.

/// @dev Designed to prevent footguns. You cannot lock to level 2 from level 1
/// with the same sender that locked from level 0 to level 1.
/// This stops reentrancy attacks that could be theoretically possible
/// if a developer misconfigures this contract.

/// @dev if there are three levels to your system, something has probably
/// gone horribly wrong in the design phase of your system. You should not
/// have more than 2 levels of reentrancy lock in your system.

contract BaseGlobalReentrancyLock {
    /// ------------- System Invariants ---------------

    /// locking: 
    ///   lockLevel1 = lockLevel0 + 1
    ///   if locklevel1 != not entered assert(block.number == lastBlockEntered)
    ///   if locklevel1 != not entered assert(msg.sender != lastSender)
    ///   lockLevel1 <= maxLockLevel
    
    /// unlocking: 
    ///   lockLevel1 = lockLevel0 - 1
    ///   block.number == lastBlockEntered
    ///   if lockLevel1 == not entered assert(msg.sender == original locker)
    ///   if locklevel1 != not entered assert(msg.sender != lastSender)

    /// -------------------------------------------------
    /// -------------------------------------------------
    /// --------- Single Storage Slot Per Lock ----------
    /// -------------------------------------------------
    /// -------------------------------------------------

    /// @notice cache the address that locked the system
    /// only this address can unlock it
    address public lastSender;

    /// @notice store the last block entered
    /// if last blockentered was in the past and status
    /// is entered, the system is in an invalid state
    /// which means that actions should be allowed
    uint88 public lastBlockEntered;

    /// @notice system lock level
    uint8 public lockLevel;

    /// @notice maximum lock level of system
    uint8 public immutable maxLockLevel;

    constructor (uint8 _maxLockLevel) {
        maxLockLevel = _maxLockLevel;
    }

    /// ---------- View Only APIs ----------

    /// @notice returns true if the contract is not currently entered
    /// at level 1 and 2, returns false otherwise
    function isUnlocked() external view returns (bool) {
        return lockLevel == Constants._NOT_ENTERED;
    }

    /// @notice returns whether or not the contract is currently locked
    function isLocked() external view returns (bool) {
        return lockLevel != Constants._NOT_ENTERED;
    }

    /// @notice set the status to entered
    /// only available if not entered at level 1 and level 2
    /// Only callable by locker role
    function _lock(uint8 toLock) internal {
        uint8 currentLevel = lockLevel; /// cache to save 1 warm SLOAD

        require(
            toLock == currentLevel + 1,
            "GlobalReentrancyLock: invalid lock level"
        );
        require(
            toLock <= maxLockLevel,
            "GlobalReentrancyLock: exceeds lock state"
        );

        /// only store the sender and lastBlockEntered if first caller (locking to level 1)
        if (currentLevel == Constants._NOT_ENTERED) {
            /// - lock to level 1 from level 0

            uint88 blockEntered = uint88(block.number);

            lastSender = msg.sender;
            lastBlockEntered = blockEntered;
        } else {
            /// - lock to level i + 1 from level i

            /// ------ increasing lock level flow ------

            /// do not update sender, to ensure original sender gets checked on final unlock
            /// do not update lastBlockEntered because it should be the same, if it isn't, revert
            /// if already entered, ensure entry happened this block
            require(
                block.number == lastBlockEntered,
                "GlobalReentrancyLock: system not entered this block"
            );

            /// do not allow the initial locker contract to lock again as that could enable reentrancy
            require(
                msg.sender != lastSender,
                "GlobalReentrancyLock: reentrant"
            );
        }

        lockLevel = toLock;

        /// ----------- invariants for SMT solver -----------
        assert(toLock == currentLevel + 1);
        assert(block.number == lastBlockEntered);
        assert(lockLevel <= maxLockLevel);
        assert(lockLevel == toLock);
    }

    /// @notice set the status to not entered
    /// only available if entered and entered in same block
    /// otherwise, system is in an indeterminate state and no execution should be allowed
    /// can only be called by the last address to lock the system
    /// to prevent incorrect system behavior
    /// Only callable by locker level 1 role
    /// @dev toUnlock can only be _ENTERED_LEVEL_ONE or _NOT_ENTERED
    /// currentLevel cannot be _NOT_ENTERED when this function is called
    function _unlock(uint8 toUnlock) internal {
        uint8 currentLevel = lockLevel; /// save 1 warm SLOAD

        require(
            uint88(block.number) == lastBlockEntered,
            "GlobalReentrancyLock: not entered this block"
        );
        require(
            currentLevel != Constants._NOT_ENTERED,
            "GlobalReentrancyLock: system not entered"
        );

        /// if started at level 1, locked up to level 2,
        /// and trying to lock down to level 0,
        /// fail as that puts us in an invalid state

        require(
            toUnlock == currentLevel - 1,
            "GlobalReentrancyLock: unlock level must be 1 lower"
        );

        if (toUnlock == Constants._NOT_ENTERED) {
            /// - unlock to level 0 from level 1, verify sender is original locker
            require(
                msg.sender == lastSender,
                "GlobalReentrancyLock: caller is not locker"
            );
            assert(msg.sender == lastSender); /// invariant for SMT solver, should always be true
        } else {
            /// if not fully unlocking, ensure sender is not original locker
            require(
                msg.sender != lastSender,
                "GlobalReentrancyLock: invalid unlock"
            );
        }

        lockLevel = toUnlock;

        assert(toUnlock == currentLevel - 1); /// invariant for SMT solver
    }
}
