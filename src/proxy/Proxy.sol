// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.11;

import "../utils/DeterministicAddress.sol";
/**
*@notice RUN OPTIMIZER OFF
 */
/**
 * @notice Proxy is a delegatecall reverse proxy implementation
 * the forwarding address is stored at the slot location of not(0)
 * if not(0) has a value stored in it that is of the form 0Xca11c0de15dead10cced0000< address >
 * the proxy may no longer be upgraded using the internal mechanism. This does not prevent the implementation
 * from upgrading the proxy by changing this slot.
 * The proxy may be directly upgraded ( if the lock is not set )
 * by calling the proxy from the factory address using the format
 * abi.encodeWithSelector(0xca11c0de, <address>);
 * All other calls will be proxied through to the implementation.
 * The implementation can not be locked using the internal upgrade mechanism due to the fact that the internal
 * mechanism zeros out the higher order bits. Therefore, the implementation itself must carry the locking mechanism that sets
 * the higher order bits to lock the upgrade capability of the proxy.
 */
contract Proxy {
    address private immutable factory_;
    constructor() {
        factory_ = msg.sender;
    }

    fallback() external payable {
        // make local copy of factory since immutables
        // are not accessable in assembly as of yet
        address factory = factory_;
        assembly {
            // admin is the builtin logic to change the implementation
            function admin() {
                // this is an assignment to implementation
                let newImpl := shr(96, shl(96, calldataload(0x04)))
                if eq(shr(160, sload(not(returndatasize()))), 0xca11c0de15dead10cced0000) {
                    mstore(returndatasize(), "imploc")
                    revert(returndatasize(), 0x20)
                }
                // store address into slot
                sstore(not(returndatasize()), newImpl)
                stop()
            }

            // passthrough is the passthrough logic to delegate to the implementation
            function passthrough() {
                // load free memory pointer
                let _ptr := mload(0x40)
                // allocate memory proportionate to calldata
                mstore(0x40, add(_ptr, calldatasize()))
                // copy calldata into memory
                calldatacopy(_ptr, returndatasize(), calldatasize())
                let ret := delegatecall(
                    gas(),
                    sload(not(returndatasize())),
                    _ptr,
                    calldatasize(),
                    returndatasize(),
                    returndatasize()
                )
                returndatacopy(_ptr, 0x00, returndatasize())
                if iszero(ret) {
                    revert(_ptr, returndatasize())
                }
                return(_ptr, returndatasize())
            }

            // if caller is factory,
            // and has 0xca11c0de<address> as calldata
            // run admin logic and return
            if eq(caller(), factory) {
                if eq(calldatasize(), 0x24) {
                    if eq(shr(224, calldataload(0x00)), 0xca11c0de) {
                        admin()
                    }
                }
            }
            // admin logic was not run so fallthrough to delegatecall
            passthrough()
        }
    }
}

abstract contract ProxyUpgrader {
    function __upgrade(address _proxy, address _newImpl) internal {
        bytes memory cdata = abi.encodeWithSelector(0xca11c0de, _newImpl);
        assembly {
            if iszero(call(gas(), _proxy, 0, add(cdata, 0x20), mload(cdata), 0x00, 0x00)) {
                let ptr := mload(0x40)
                mstore(0x40, add(ptr, returndatasize()))
                returndatacopy(ptr, 0x00, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }
}

abstract contract DeterministicAccessControl is DeterministicAddress {
    modifier onlyContract(address _factory, bytes32 _salt) {
        require(
            msg.sender == DeterministicAddress.getMetamorphicContractAddress(_salt, _factory),
            "notAuth"
        );
        _;
    }
}

abstract contract ProxyInternalUpgradeLock {
    function __lockImplementation() internal {
        assembly {
            let implSlot := not(0x00)
            sstore(
                implSlot,
                or(
                    0xca11c0de15dead10cced00000000000000000000000000000000000000000000,
                    sload(implSlot)
                )
            )
        }
    }
}

abstract contract ProxyInternalUpgradeUnlock {
    function __unlockImplementation() internal {
        assembly {
            let implSlot := not(0x00)
            sstore(
                implSlot,
                and(
                    0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff,
                    sload(implSlot)
                )
            )
        }
    }
}


