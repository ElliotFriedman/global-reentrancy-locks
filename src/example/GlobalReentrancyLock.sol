// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {BaseGlobalReentrancyLock} from "./../BaseGlobalReentrancyLock.sol";
import {Constants} from "../Constants.sol";

/// @notice inpsired by the openzeppelin reentrancy guard smart contracts
/// data container size has been changed.

/// @dev allows contracts and addresses with the LOCKER role to call
/// in and lock and unlock this smart contract.
/// once locked, only the original caller that locked can unlock the contract
/// without the governor emergency unlock functionality.
/// Governor can unpause if locked but not unlocked.

/// @notice explanation on data types used in contract

/// @dev block number can be safely downcasted without a check on exceeding
/// uint88 max because the sun will explode before this statement is true:
/// block.number > 2^88 - 1
/// address can be stored in a uint160 because an address is only 20 bytes

/// @dev in the EVM. 160bits / 8 bits per byte = 20 bytes
/// https://docs.soliditylang.org/en/develop/types.html#address

contract GlobalReentrancyLock is BaseGlobalReentrancyLock {
    constructor() BaseGlobalReentrancyLock(2) { /// allow locking up to 2 levels
        require(block.chainid != 1); /// don't deploy this contract on mainnet, it is only an example
        /// echidna won't work with this check around chainid, so comment out for echidna testing
        /// contract adding access control is mandatory for the base contract to work in production
    }

    /// ---------- Global Locker Role State Changing APIs ----------

    /// @notice set the status to entered
    /// Callable only by locker role
    /// @dev only valid state transitions:
    /// - lock to level 1 from level 0
    /// - lock to level 2 from level 1
    /// @notice do not use in production without access controls. This is an example only
    function lock(
        uint8 toLock
    ) public {
        _lock(toLock);
    }

    /// @notice set the status to not entered
    /// only available if entered in same block
    /// otherwise, system is in an indeterminate state and no execution should be allowed
    /// can only be called by the last address to lock the system
    /// to prevent incorrect system behavior
    /// Only callable by sender's with the locker role
    /// @dev toUnlock can only be _ENTERED_LEVEL_ONE or _NOT_ENTERED
    /// currentLevel cannot be _NOT_ENTERED when this function is called
    /// @dev only valid state transitions:
    /// - unlock to level 0 from level 1 as original locker in same block as lock
    /// - lock from level 2 down to level 1 in same block as lock
    /// @notice do not use in production without access controls. This is an example only
    function unlock(
        uint8 toUnlock
    ) external {
        _unlock(toUnlock);
    }
}
