// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {GlobalReentrancyLock} from "../../../src/example/GlobalReentrancyLock.sol";
import {Constants} from "./../../../src/Constants.sol";

contract EchidnaTest is GlobalReentrancyLock {
    function echidna_property() public view returns (bool) {
        return lockLevel <= maxLockLevel;
    }

    function echidna_property_lock() public view returns (bool) {
        if (this.isLocked()) {
            return lockLevel > 0;
        }

        return true;
    }
}
