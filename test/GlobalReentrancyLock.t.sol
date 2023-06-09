// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {Test} from "@forge-std/Test.sol";
import {ExampleGlobalReentrancyLock} from "../src/example/ExampleGlobalReentrancyLock.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract TestGlobalReentrancyLock is Test {

    ExampleGlobalReentrancyLock public lock;

    function setUp() public {
        lock = new ExampleGlobalReentrancyLock();
    }

    function testSetup() public {
        assertTrue(!lock.isLocked());
        assertTrue(lock.isUnlocked());
        assertEq(lock.lockLevel(), 0);
        assertEq(lock.maxLockLevel(), 1);
        assertEq(lock.lastBlockEntered(), 0);
        assertEq(lock.lastSender(), address(0));
    }

    function testLock() public {
        lock.lock(1);

        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());
        assertEq(lock.lockLevel(), 1);
    }
    
    function testUnlock() public {
        testLock();

        lock.unlock(0);

        assertTrue(!lock.isLocked());
        assertTrue(lock.isUnlocked());
        assertEq(lock.lockLevel(), 0);
    }

    function testLockOverMaxLockLevelFails() public {
        testLock();

        vm.expectRevert("GlobalReentrancyLock: exceeds lock state");
        lock.lock(2);
    }

    function testUnlockSystemNotEntered() public {
        testUnlock();

        vm.expectRevert("GlobalReentrancyLock: system not entered");
        lock.unlock(0);
    }

    function testUnlockDifferentSender() public {
        testLock();

        address sender = address(10);
        lock.grantRole(lock.locker(), sender);

        vm.expectRevert("GlobalReentrancyLock: caller is not locker");
        vm.prank(sender);
        lock.unlock(0);
    }

    function testUnlockNotLower() public {
        testLock();

        vm.expectRevert("GlobalReentrancyLock: unlock level must be 1 lower");
        lock.unlock(1);
    }

    /// block number tests
    function testUnlockDifferentBlockFails() public {
        testLock();
        vm.roll(block.number + 1);

        vm.expectRevert("GlobalReentrancyLock: not entered this block");
        lock.unlock(0);
    }

    function testAcl() public {
        string memory lockerErrorMessage = _getAclErrorMessage(lock.locker(), address(1));

        vm.startPrank(address(1));

        vm.expectRevert(bytes(lockerErrorMessage));
        lock.lock(1);

        vm.expectRevert(bytes(lockerErrorMessage));
        lock.unlock(1);

        string memory govErrorMessage = _getAclErrorMessage(lock.governor(), address(1));

        vm.expectRevert(bytes(govErrorMessage));
        lock.governorEmergencyUnlock();

        vm.stopPrank();
    }

    function testGovernorEmergencyUnlockFailsEnteredSameBlock() public {
        testLock();

        vm.expectRevert("ExampleGlobalReentrancyLock: governor cannot unlock");
        lock.governorEmergencyUnlock();
    }

    function testGovernorEmergencyUnlockSucceeds() public {
        testLock();

        vm.roll(block.number + 1);
        lock.governorEmergencyUnlock();

        assertTrue(!lock.isLocked());
        assertTrue(lock.isUnlocked());
    }

    function _getAclErrorMessage(bytes32 role, address account) internal pure returns (string memory) {
        return(
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(account),
                    " is missing role ",
                    Strings.toHexString(uint256(role), 32)
                )
            )
        );
    }
}
