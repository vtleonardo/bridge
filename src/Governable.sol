// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;

import "./interfaces/IGovernance.sol";

abstract contract Governable {

    // _governance is a privileged contract
    IGovernance _governance;

    constructor(IGovernance governance_) {
        _governance = governance_;
    }
 
    // onlyGovernance is a modifer that enforces a call
    // must be performed by a governance contract
    modifier onlyGovernance() {
        require(_governance.isGovernance(msg.sender), "Governable: Action must be performed by a governance contract!");
        _;
    }

    function _setGovernance(IGovernance governance_) internal {
        _governance = governance_;
    }
}