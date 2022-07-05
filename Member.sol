pragma solidity ^0.8.0;

// SPDX-License-Identifier: SimPL-2.0

import "./ContractOwner.sol";
import "./Manager.sol";

abstract contract Member is ContractOwner {
    Manager public manager;

    function __initializeMember() internal initializer {
        contractOwner = msg.sender;
    }

    function setManager(address addr) external ContractOwnerOnly {
        manager = Manager(addr);
    }
}
