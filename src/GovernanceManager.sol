// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;

import "./GovernanceStorage.sol";
import "./Governance.sol";
import "./Governable.sol";
import "./interfaces/INFTStake.sol";

contract GovernanceManager is Governance, Governable, GovernanceStorage {

    address allowedProposal;

    constructor(address Stake_, address MinerStake_) Governable(this) {
        _Stake = INFTStake(Stake_);
        _MinerStake = INFTStake(MinerStake_);
        _threshold = (220000000/2 + 220000000/100) * 10**18;
    }

    function propose(address logic_) public returns(uint256 proposalID) {
        Proposal memory proposal = Proposal(true, logic_, 0, block.number + _maxGovernanceLock);
        proposalID = _increment();
        _proposals[proposalID] = proposal;
    }
    
    function getProposal(uint256 proposalID_) public view returns(Proposal memory) {
        return _proposals[proposalID_];
    }
    
    function execute(uint256 proposalID_) public {
        require(_getCount() >= proposalID_, "GovernanceManager: Invalid proposal ID");
        Proposal memory proposal = _proposals[proposalID_];
        require(proposal.voteCount >= _threshold, "GovernanceManager: Proposal does not have enough votes");
        require(proposal.notExecuted == true, "GovernanceManager: This proposal has been executed already");
        proposal.notExecuted = false;
        _proposals[proposalID_] = proposal;
        // temporarily grant governance permission to proposal logic contract
        allowedProposal = proposal.logic;
        (bool success, ) = proposal.logic.call(abi.encodeWithSignature("execute()"));
        require(success, "GovernanceManager: CALL FAILED to proposal execute()");
        // remove governance permission from proposal logic contract
        allowedProposal = address(0);
    }

    function _vote(INFTStake staking_, uint256 proposalID_, uint256 tokenID_) internal {
        require(_getCount() >= proposalID_, "GovernanceManager: Invalid proposal ID");
        Proposal memory proposal = _proposals[proposalID_];
        require(proposal.blockEndVote >= block.number, "GovernanceManager: Cannot vote on this proposal anymore");
        require(proposal.notExecuted == true, "GovernanceManager: This proposal has been executed already");
        require(_votemap[proposalID_][address(staking_)][tokenID_] == false, "GovernanceManager: You already voted on this proposal");
        _votemap[proposalID_][address(staking_)][tokenID_] = true;
        uint256 numberShares = staking_.lockPosition(msg.sender, tokenID_, proposal.blockEndVote - block.number + 1);
        proposal.voteCount += numberShares;
        _proposals[proposalID_] = proposal;
    }

    function voteAsMiner(uint256 proposalID_, uint256 tokenID_) public {
        INFTStake staking = _MinerStake;
        _vote(staking, proposalID_, tokenID_);
    }

    function voteAsStaker(uint256 proposalID_, uint256 tokenID_) public {
        INFTStake staking = _Stake;
        _vote(staking, proposalID_, tokenID_);
    }
    
    function isGovernance(address addr_) public view override returns(bool) {
        return addr_ == address(this) || addr_ == allowedProposal;
    }

    function setThreshold(uint256 threshold_) public onlyGovernance {
        _threshold = threshold_;
    }
}
