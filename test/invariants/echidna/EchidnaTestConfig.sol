// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {EchidnaTest, Constants} from "./EchidnaTest.sol";

/// This contract must be run with the echidna config yml file provided,
/// otherwise the properties will fail
contract EchidnaTestConfig is EchidnaTest {
    function echidna_property_single_block() public view returns (bool) {
        if (block.number != lastBlockEntered) {return true;} /// should never advance blocks due to config file

        return lastBlockEntered == block.number;
    }

    function echidna_property_sender() public view returns (bool) {
        /// either lock is not entered, or sender is the specified sender from yml
        return lastSender == address(0x42424242) || Constants._NOT_ENTERED == lockLevel;
    }

    function echidna_property_last_entered() public view returns (bool) {
        if (block.number != lastBlockEntered) {return true;}
        return (lockLevel != Constants._NOT_ENTERED && block.number == lastBlockEntered) || lockLevel == Constants._NOT_ENTERED;
    }
}
