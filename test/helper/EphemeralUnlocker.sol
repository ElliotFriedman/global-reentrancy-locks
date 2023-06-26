pragma solidity 0.8.20;

import {GlobalReentrancyLock} from "@protocol/example/GlobalReentrancyLock.sol";

contract EphemeralUnlocker {
    GlobalReentrancyLock public lock;

    constructor(GlobalReentrancyLock _lock) {
        lock = _lock;
        uint8 currentLevel = lock.lockLevel();
        lock.unlock(currentLevel - 1);
        selfdestruct(payable(msg.sender));
    }
}
