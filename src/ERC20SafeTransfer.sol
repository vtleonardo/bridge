// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.7.6;

import "./interfaces/IERC20Transfer.sol";


abstract contract ERC20SafeTransfer {
    
    // _safeTransferFromERC20 performs a transferFrom call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting 
    // if amount_ is zero
    function _safeTransferFromERC20(IERC20Transfer contract_, address sender_, uint256 amount_) internal {
        if (amount_ == 0 ){
            return;
        }
        bool success = contract_.transferFrom(sender_, address(this), amount_);
        require(success, "Transfer failed.");
    }
    
    // _safeTransferERC20 performs a transfer call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting 
    // if amount_ is zero
    function _safeTransferERC20(IERC20Transfer contract_, address to_, uint256 amount_) internal {
        if (amount_ == 0 ){
            return;
        }
        bool success = contract_.transfer(to_, amount_);
        require(success, "Transfer failed.");
    }
}