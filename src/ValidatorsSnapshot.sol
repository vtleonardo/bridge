// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.15;

import "ds-stop/stop.sol";

import "./Constants.sol";
import "./Crypto.sol";
import "./ETHDKG.sol";
import "./QueueLibrary.sol";
import "./Registry.sol";
import "./Staking.sol";
import "./SignatureLibrary.sol";
import "./SimpleAuth.sol";

contract ValidatorsSnapshot is Constants, DSStop, SimpleAuth, ValidatorsStorage {

    function extractUint32(bytes memory src, uint idx) public pure returns (uint32 val) {
        val = uint8(src[idx+3]);
        val = (val << 8) | uint8(src[idx+2]);
        val = (val << 8) | uint8(src[idx+1]);
        val = (val << 8) | uint8(src[idx]);
    }

    function extractUint256(bytes memory src, uint offset) public pure returns (uint256 val) {
        for (uint idx = offset+31; idx > offset; idx--) {
            val = uint8(src[idx]) | (val << 8);
        }

        val = uint8(src[offset]) | (val << 8);
    }

    function reverse(bytes memory orig) public pure returns (bytes memory reversed) {
        reversed = new bytes(orig.length);
        for (uint idx = 0; idx<orig.length; idx++) {
            reversed[orig.length-idx-1] = orig[idx];
        }
    }

    function parseSignatureGroup(bytes memory _signatureGroup) public pure returns (uint256[4] memory publicKey, uint256[2] memory signature) {

        // Go big.Ints are big endian but Solidity is little endian
        bytes memory signatureGroup = reverse(_signatureGroup);

        signature[1] = extractUint256(signatureGroup, 0);
        signature[0] = extractUint256(signatureGroup, 32);
        publicKey[3] = extractUint256(signatureGroup, 64);
        publicKey[2] = extractUint256(signatureGroup, 96);
        publicKey[1] = extractUint256(signatureGroup, 128);
        publicKey[0] = extractUint256(signatureGroup, 160);
    }

    function snapshot(bytes calldata _signatureGroup, bytes calldata _bclaims) external stoppable returns (bool) {

        uint256[4] memory publicKey;
        uint256[2] memory signature;
        (publicKey, signature) = parseSignatureGroup(_signatureGroup);

        bytes memory blockHash = abi.encodePacked(keccak256(_bclaims));

        bool ok;
        bytes memory res;
        (ok, res) = address(crypto).call(abi.encodeWithSignature("Verify(bytes,uint256[2],uint256[4])", blockHash, signature, publicKey)); // solium-disable-line
        require(ok, "Signature verification failed");

        // Extract
        uint32 chainId = extractUint32(_bclaims, 8);
        uint32 height = extractUint32(_bclaims, 12);

        // Store snapshot
        Snapshot storage currentSnapshot = snapshots[epoch];
        currentSnapshot.saved = true;
        currentSnapshot.rawBlockClaims = _bclaims;
        currentSnapshot.rawSignature = _signatureGroup;
        currentSnapshot.ethHeight = uint32(block.number);
        currentSnapshot.madHeight = height;
        currentSnapshot.chainId = chainId;

        if (epoch > 1) {
            Snapshot memory previousSnapshot = snapshots[epoch-1];

            require(
                !previousSnapshot.saved || block.number >= previousSnapshot.ethHeight + ETH_SNAPSHOT_SIZE,
                "snapshot heights too close in Ethereum"
            );

            require(
                !previousSnapshot.saved || height >= previousSnapshot.madHeight + MAD_SNAPSHOT_SIZE,
                "snapshot heights too close in MadNet"
            );

        }

        bool reinitEthdkg;
        if (validatorsChanged) {
            reinitEthdkg = true;
        }
        validatorsChanged = false;

        emit SnapshotTaken(chainId, epoch, height, msg.sender, validatorsChanged);

        epoch++;

        return false;
    }

}