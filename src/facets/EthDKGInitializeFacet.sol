// SPDX-License-Identifier: MIT-open-group
pragma solidity >=0.7.4;

import "../Constants.sol";
import "../Registry.sol";

import "./AccessControlLibrary.sol";
import "./EthDKGLibrary.sol";

contract EthDKGInitializeFacet is AccessControlled, Constants {

    function initializeState() external onlyOperator {
        EthDKGLibrary.initializeState();
    }

    function initializeEthDKG(Registry registry) external onlyOperator {

        address validatorsAddr = registry.lookup(VALIDATORS_CONTRACT);
        require(validatorsAddr != address(0), "missing validators address");

        EthDKGLibrary.EthDKGStorage storage es = EthDKGLibrary.ethDKGStorage();

        es.initial_message = abi.encodePacked("Cryptography is great");
        es.validators = Validators(validatorsAddr);
        es.DELTA_INCLUDE = 40;
        es.DELTA_CONFIRM = 6;
        es.MINIMUM_REGISTRATION = 4;
    }

    function updatePhaseLength(uint256 phaseLength) external onlyOperator {
        EthDKGLibrary.ethDKGStorage().DELTA_INCLUDE = phaseLength;
    }

    function initializeEthDKGFromArbitraryMadHeight(uint32 _madHeight) public returns(bool) {
        EthDKGLibrary.EthDKGStorage storage es = EthDKGLibrary.ethDKGStorage();

        uint32 epoch = uint32(es.validators.epoch()) - 1; // validators is always set to the _next_ epoch
        uint32 ethHeight = uint32(es.validators.getHeightFromSnapshot(epoch));

        // store ethDKGMadHeight = _madHeight
        es.ethDKGMadHeight = _madHeight;

        emit EthDKGLibrary.ValidatorSet(
            uint8(0),
            epoch,
            ethHeight,
            _madHeight,
            0x0,
            0x0,
            0x0,
            0x0
        );

        return true;
    }

}