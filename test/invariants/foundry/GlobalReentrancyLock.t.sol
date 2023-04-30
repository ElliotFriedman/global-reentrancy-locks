// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.13;

import {Vm} from "@forge-std/Vm.sol";
import {Test} from "@forge-std/Test.sol";
import {GlobalReentrancyLock} from "../../../src/example/GlobalReentrancyLock.sol";

/// note all variables have to be public and not immutable otherwise foundry
/// will not run invariant tests

/// @dev Modified from Solmate ERC20 Invariant Test (https://github.com/transmissions11/solmate/blob/main/src/test/ERC20.t.sol)
contract InvariantTestGlobalReentrancyLock is Test {
    GlobalReentrancyLock public lock;
    GlobalReentrancyLockTest public grlTest;

    function setUp() public {
        lock = new GlobalReentrancyLock();

        grlTest = new GlobalReentrancyLockTest(lock);

        targetContract(address(grlTest));
    }

    function invariant_Locked() public {
        if (lock.lockLevel() > 0) {
            assertTrue(lock.isLocked());
            assertTrue(!lock.isUnlocked());
        } else {
            assertTrue(!lock.isLocked());
            assertTrue(lock.isUnlocked());
        }
    }

    function invariant_LtMax() public {
        assertTrue(lock.lockLevel() <= lock.maxLockLevel());
    }

    function invariant_CorrectLockLevel() public {
        assertEq(grlTest.currentLockLevel(), lock.lockLevel());
    }

    function invariant_NotLockedAndUnlocked() public {
        assertTrue(lock.isLocked() != lock.isUnlocked()); /// cannot be both locked and unlocked at the same time
    }

    function invariant_SenderBlockCorrect() public {
        if (lock.isLocked()) {
            assertEq(lock.lastSender(), address(grlTest));
            assertEq(lock.lastBlockEntered(), block.number);
        }
    }
}

contract GlobalReentrancyLockTest is Test {
    uint256 public currentLockLevel;

    GlobalReentrancyLock public lock;

    constructor(GlobalReentrancyLock _lock) {
        lock = _lock;
    }

    function lockGrl() public {
        uint8 currentLevel = lock.lockLevel();
        lock.lock(currentLevel + 1);
        currentLockLevel++;
    }

    function unlockGrl() public {
        uint8 currentLevel = lock.lockLevel();
        lock.lock(currentLevel - 1);
        currentLockLevel--;
    }
}
