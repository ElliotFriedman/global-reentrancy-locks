// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {GlobalReentrancyLock} from "./GlobalReentrancyLock.sol";

contract HevmSymbolicTest is GlobalReentrancyLock {
    /// if max lock level is 10, and we use InitialS in HEVM, this invariant should never be violated
    /// however, without a storage model, HEVM defaults to symbolic storage values, which allows it
    /// to find an assertion violation
    function stateLockingInvariant() public view {
        assert(lockLevel <= maxLockLevel);
    }
}
