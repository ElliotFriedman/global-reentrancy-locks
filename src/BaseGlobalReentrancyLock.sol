// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {Constants} from "./Constants.sol";

contract BaseGlobalReentrancyLock {
    /// ------------- System Invariants ---------------

    /// locking: 
    ///   lockLevel1 = lockLevel0 + 1
    ///   if locklevel1 != not entered assert(block.number == lastBlockEntered)
    ///   lockLevel1 <= maxLockLevel

    /// unlocking: 
    ///   lockLevel1 = lockLevel0 - 1
    ///   block.number == lastBlockEntered
    ///   if lockLevel1 == not entered assert(msg.sender == original locker)

    /// when unlocking from level 1 to level 0
    /// msg.sender == original locker

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

    /// commented out to constrain search space and speed smt solving
    /// @notice maximum lock level of system
    // uint256 public immutable maxLockLevel;
    
    uint256 public constant maxLockLevel = 10;

    /// commented out to speed smt solving
    // constructor (uint256 _maxLockLevel) {
    //     maxLockLevel = _maxLockLevel;
    // }

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
            assert(msg.sender == lastSender);
        }

        lockLevel = toUnlock;

        assert(toUnlock == currentLevel - 1); /// invariant for SMT solver
    }
}
