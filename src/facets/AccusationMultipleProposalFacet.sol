// SPDX-License-Identifier: MIT-open-group
pragma solidity >=0.5.15;

import "./AccusationLibrary.sol";
import "./AccessControlLibrary.sol";
import "../interfaces/AccusationEvents.sol";
import "../SafeMath.sol";


contract AccusationMultipleProposalFacet is AccessControlled, AccusationEvents {

    using SafeMath for uint256;

    function initializeAccusation(Registry registry) external view onlyOperator {
        require(address(registry) != address(0), "nil registry address");
    }

    /// @notice This function validates an accusation of multiple proposals.
    /// @param _signature0 The signature of pclaims0
    /// @param _pClaims0 The PClaims of the accusation
    /// @param _signature1 The signature of pclaims1
    /// @param _pClaims1 The PClaims of the accusation
    /// @dev Execution cost: 36608 gas
    function AccuseMultipleProposal(
        bytes calldata _signature0,
        bytes calldata _pClaims0,
        bytes calldata _signature1,
        bytes calldata _pClaims1
    ) external {
        AccusationLibrary.AccusationStorage storage s = AccusationLibrary.accusationStorage();
        address signer = AccusationLibrary.AccuseMultipleProposal(_signature0, _pClaims0, _signature1, _pClaims1);
        s.accusations[signer] = s.accusations[signer].add(1);
        emit MultipleProposals(signer);
    }
}
