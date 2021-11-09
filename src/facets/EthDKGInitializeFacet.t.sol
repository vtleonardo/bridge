// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./Setup.t.sol";


contract EthDKGInitializeFacetTest is Constants, DSTest, Setup {

    address me = address(this);

    function testSetArbitraryMadHeight() public {
        ethdkg.initializeEthDKG(registry);

        ethdkg.initializeEthDKGFromArbitraryMadHeight(100);
        assertEq(ethdkg.getEthDKGMadHeight(), 100);
    }

    function testFail_testSetArbitraryMadHeightBeforePreviousCompletion() public {
        ethdkg.initializeEthDKG(registry);

        ethdkg.initializeEthDKGFromArbitraryMadHeight(100);
        assertEq(ethdkg.getEthDKGMadHeight(), 100);

        ethdkg.initializeEthDKGFromArbitraryMadHeight(50);
    }

}
