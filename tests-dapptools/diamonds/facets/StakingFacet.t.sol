// SPDX-License-Identifier: MIT-open-group
pragma solidity >=0.7.4;

import "lib/ds-test/test.sol";

import "../Setup.t.sol";
import "src/diamonds/facets/DiamondUpdateFacet.sol";
import "src/diamonds/facets/ParticipantsFacet.sol";
import "src/diamonds/facets/SnapshotsFacet.sol";
import "src/diamonds/facets/StakingFacet.sol";

import "src/QueueLibrary.sol";
import "src/Registry.sol";
import "src/Token.sol";

import "src/diamonds/ValidatorsDiamond.sol";
import "src/diamonds/interfaces/Snapshots.sol";
import "src/diamonds/interfaces/Staking.sol";
import "src/diamonds/interfaces/Token.sol";
import "src/diamonds/interfaces/Validators.sol";

contract StakingFacetTest is Constants, DSTest, Setup {

    address me = address(this);

    function testSetDelay() public {
        staking.setEpochDelay(2);
    }

    function testUtilityBalance() public {
        uint256 actualBalance = utilityToken.balanceOf(address(validators));
        assertEq(actualBalance, 0);
    }

    function testInitialization() public {
        staking.initializeStaking(registry);
    }

    function testLockStake() public {
        uint256 startingBalance = staking.balanceStakeFor(me);
        assertEq(startingBalance, 0);

        staking.lockStakeFor(me, 1_000_000);

        uint256 endingBalance = staking.balanceStakeFor(me);
        assertEq(endingBalance, 1_000_000);
    }

    function testLockReward() public {
        uint256 startingBalance = staking.balanceRewardFor(me);
        assertEq(startingBalance, 0);

        staking.lockRewardFor(me, 10, 1);
        staking.lockRewardFor(me, 10, 2);
        staking.lockRewardFor(me, 10, 3);

        uint256 endingBalance = staking.balanceRewardFor(me);
        assertEq(endingBalance, 30);
    }

    function testSimpleLockReward() public {
        for (uint160 idx; idx < 20; idx++) {
            staking.lockRewardFor(address(idx+1), 10, 1);
        }
    }

    function testUnlockRewardFor2() public {
        assertEq(staking.balanceUnlockedFor(me), 0);

        staking.lockRewardFor(me, 10, 1);
        staking.lockRewardFor(me, 10, 2);
        staking.lockRewardFor(me, 10, 3);
        assertEq(staking.balanceRewardFor(me), 30);

        snapshots.setEpoch(2);
        staking.unlockRewardFor(me);
        assertEq(staking.balanceUnlockedRewardFor(me), 20); // first 2 rewards have been unlocked
        assertEq(staking.balanceRewardFor(me), 10); // only one reward is left
    }

    function testUnlockRewardFor3() public {
        staking.lockRewardFor(me, 10, 1);
        staking.lockRewardFor(me, 10, 2);
        staking.lockRewardFor(me, 10, 3);
        assertEq(staking.balanceRewardFor(me), 30);

        snapshots.setEpoch(3);
        staking.unlockRewardFor(me);
        assertEq(staking.balanceUnlockedRewardFor(me), 30); // all rewards are unlocked
        assertEq(staking.balanceRewardFor(me), 0); // no reward is still locked
    }

    function testFine() public {

    }

    function testBurn() public {
        staking.lockStakeFor(me, 1_000_000);

        assertEq(staking.balanceStakeFor(me), 1_000_000);

        staking.burn(me);
        assertEq(staking.balanceStakeFor(me), 0);
    }


}