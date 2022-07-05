pragma solidity ^0.8.0;
// SPDX-License-Identifier: SimPL-2.0

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
abstract contract ContractOwner is Initializable {
    address public contractOwner;
    
    modifier ContractOwnerOnly {
        require(msg.sender == contractOwner, "contract owner only");
        _;
    }
}
