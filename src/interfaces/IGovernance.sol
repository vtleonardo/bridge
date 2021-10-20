// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;

interface IGovernance {

    function isGovernance(address addr_) external view returns(bool);
}