// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

///   Building the global reentrancy lock, I had an idea.
/// What if, instead of applying locks to all functions, you gate 
/// all user facing functions behind a single entry point smart
/// contract that has a reentrancy lock. Then, a user specifies
/// the contract in your system to call, and the calldata.
/// The global entry contract then forwards the msg.sender,
/// and calldata to the specified address. This way, even if
/// there are unsafe external calls, you can't re-enter the system
/// and change state. This could be potentially
/// dangerous if token approvals are done incorrectly.
/// All system contracts would then store the address of the base 
/// global entry contract, and only allow this contract to call.
/// This would add an additional CALL + SLOAD to each transaction,
/// however this would only be one additional SLOAD as compared to
/// the BaseGlobalReentrancyLock.
contract BaseGlobalEntry is ReentrancyGuard {

    function exec(address toCall, bytes calldata data) external nonReentrant {
        (bool success, ) = toCall.call{value: 0}(abi.encode(msg.sender, data));
        require(success, "BaseGlobalEntry: recipient reverted");
    }
}

///  The token approval pattern would be strange here, 
/// a user approves the example contract, then calls the global entry,
/// the global entry reads msg.sender passed from global entry and
/// pulls tokens from that users allowance.
contract ExampleContract {
    BaseGlobalEntry public entry;

    constructor(BaseGlobalEntry _entry) {
        entry = _entry;
    }

    modifier onlyEntry {
        require(msg.sender == address(entry), "ExampleContract: invalid caller");
        _;
    }

    function mint(bytes calldata data) external onlyEntry {
        /// ...decode calldata
        /// ...do logic
    }

    function redeem(bytes calldata data) external onlyEntry {
        /// ...decode calldata
        /// ...do logic
    }
}
