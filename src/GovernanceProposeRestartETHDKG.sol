// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;

import "./interfaces/GovernanceProposal.sol";

contract GovernanceProposeRestartETHDKG is GovernanceProposal {
    
    function execute() public returns(bool) {
        address target = address(0);
        (bool success, ) = target.call(abi.encodeWithSignature("restartETHDKG()"));
        require(success, "CALL FAILED");
        return success;
    }
}