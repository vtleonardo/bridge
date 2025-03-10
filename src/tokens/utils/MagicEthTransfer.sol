// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;

import "./MagicValue.sol";
import "../interfaces/IMagicEthTransfer.sol";

abstract contract MagicEthTransfer is MagicValue {

    function _safeTransferEthWithMagic(IMagicEthTransfer to_, uint256 amount_) internal {
        to_.depositEth{value: amount_}(_getMagic());
    }

}