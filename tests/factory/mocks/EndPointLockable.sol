// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.11;

import "../../../src/proxy/Proxy.sol";
import "../../../src/proxy/ProxyInternalUpgradeLock.sol";
import "../../../src/proxy/ProxyInternalUpgradeUnlock.sol";

interface IEndpointlockable {
    function i() external view returns (uint256);

    function addOne() external;

    function addTwo() external;

    function factory() external returns (address);
}
/// @custom:salt EndPointLockable
contract EndPointLockable is ProxyInternalUpgradeLock, ProxyInternalUpgradeUnlock {
    address private immutable factory_;
    address public owner;
    uint256 public i;
    modifier onlyOwner() {
        requireAuth(msg.sender == owner);
        _;
    }
    event addedOne(uint256 indexed i);
    event addedTwo(uint256 indexed i);
    event upgradeLocked(bool indexed lock);
    event upgradeUnlocked(bool indexed lock);

    constructor(address f) {
        factory_ = f;
    }

    function addOne() public {
        i++;
        emit addedOne(i);
    }

    function addTwo() public {
        i = i + 2;
        emit addedTwo(i);
    }

    function upgradeLock() public {
        __lockImplementation();
        emit upgradeLocked(true);
    }

    function upgradeUnlock() public {
        __unlockImplementation();
        emit upgradeUnlocked(false);
    }

    function requireAuth(bool _ok) internal pure {
        require(_ok, "unauthorized");
    }
}
