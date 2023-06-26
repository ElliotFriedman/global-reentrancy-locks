// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {ReentrancyLockRef} from "@protocol/ReentrancyLockRef.sol";
import {GlobalReentrancyLock} from "@protocol/example/GlobalReentrancyLock.sol";
import {BaseGlobalReentrancyLock} from "@protocol/BaseGlobalReentrancyLock.sol";

contract FootGunFailMock is ReentrancyLockRef {
    constructor (GlobalReentrancyLock _lock) ReentrancyLockRef(_lock) {}

    function lockLevel1() external globalLock(1) {}

    /// @notice this should fail because locker to level 2 should be a different
    /// contract than level 1 to protect against reentrancy
    function lockLevel2() external globalLock(2) {}
}
