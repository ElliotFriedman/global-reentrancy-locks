// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {GlobalReentrancyLock} from "./GlobalReentrancyLock.sol";
import {Constants} from "../Constants.sol";

contract ExampleSystem {
    GlobalReentrancyLock public lock;
    uint256 public counter;

    constructor(GlobalReentrancyLock _lock) {
        lock = _lock;
    }

    modifier whenNotLocked() {
        uint8 currentLockLevel = lock.lockLevel();

        require(currentLockLevel == Constants._NOT_ENTERED, "System: reentrant call");

        lock.lock(currentLockLevel + 1); /// increase lock level by 1

        _;

        lock.unlock(currentLockLevel); /// decrease lock level back to starting level
    }

    /// With 1 as the max lock level in global reentrancy lock, regardless of the amount
    /// of external calls within this function, it is not possible to reenter this function
    /// even if CEI is ignored.
    function incrementCount() external whenNotLocked {
        /// external calls...

        counter++;

        /// external calls...
    }
}
