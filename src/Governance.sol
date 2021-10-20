// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;

import "./interfaces/IGovernance.sol";

abstract contract Governance is IGovernance {

    function isGovernance(address addr_) public view virtual override returns(bool) {
        return addr_ == address(this);
    }
}