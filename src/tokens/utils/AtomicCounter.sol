// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;


abstract contract AtomicCounter {

    // monotonically increasing counter
    uint256 _counter = 0;


    // _newTokenID increments the counter and returns the new value
    function _increment() internal returns (uint256 count) {
        count = _counter;
        count += 1;
        _counter = count;
        return count;
    }

    function _getCount() internal view returns (uint256) {
        return _counter;
    }
}