// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {INodeKey} from "./interfaces/INodeKey.sol";
import {INodeRewards} from "./interfaces/INodeRewards.sol";
contract MockReferee {
    using EnumerableSet for EnumerableSet.UintSet;

    event LogAttest(uint256 indexed batchNumber, uint256 indexed nodeKeyId);

    INodeKey public immutable NODE_KEY;

    INodeRewards public nodeRewards;
    uint256 public latestFinalizedBatchNumber;
    uint256 public latestConfirmedTimestamp;

    mapping(uint256 batchNumber => uint256 count)
        internal _nrOfSuccessfulAttestations;
    mapping(uint256 nodeKeyId => EnumerableSet.UintSet batchNumbers)
        internal _claimableBatches;
    mapping(uint256 nodeKeyId => uint256 index) internal _indexOfUnclaimedBatch;

    constructor(address _nodeKey) {
        NODE_KEY = INodeKey(_nodeKey);
    }

    function setNodeRewards(address _nodeRewards) external {
        nodeRewards = INodeRewards(_nodeRewards);
    }

    function attest(uint256 _batchNumber, uint256 _nodeKeyId) external {
        _attest(_batchNumber, _nodeKeyId);

        nodeRewards.onAttest(_batchNumber, _nodeKeyId);
    }

    function batchAttest(
        uint256 _batchNumber,
        uint256[] memory _nodeKeyIds
    ) external {
        for (uint256 i; i < _nodeKeyIds.length; i++) {
            _attest(_batchNumber, _nodeKeyIds[i]);
        }

        nodeRewards.onBatchAttest(_batchNumber, _nodeKeyIds);
    }

    function _attest(uint256 _batchNumber, uint256 _nodeKeyId) internal {
        _claimableBatches[_nodeKeyId].add(_batchNumber);
        _nrOfSuccessfulAttestations[_batchNumber] += 1;

        emit LogAttest(_batchNumber, _nodeKeyId);
    }

    function finalize() external {
        latestFinalizedBatchNumber += 1;

        nodeRewards.onFinalize(
            latestFinalizedBatchNumber,
            block.timestamp,
            latestConfirmedTimestamp,
            _nrOfSuccessfulAttestations[latestFinalizedBatchNumber]
        );

        latestConfirmedTimestamp = block.timestamp;
    }

    function claimReward(uint256 _nodeKeyId, uint256 _batchesCount) external {
        _claimReward(_nodeKeyId, _batchesCount);
    }

    function batchClaimReward(
        uint256[] memory _nodeKeyIds,
        uint256 _batchesCount
    ) external {
        for (uint256 i; i < _nodeKeyIds.length; i++) {
            _claimReward(_nodeKeyIds[i], _batchesCount);
        }
    }

    function _claimReward(uint256 _nodeKeyId, uint256 _batchesCount) internal {
        uint256 unclaimedIndex = _indexOfUnclaimedBatch[_nodeKeyId];

        uint256 maxClaimableBatches = _claimableBatches[_nodeKeyId].length() -
            unclaimedIndex;
        _batchesCount = _batchesCount > maxClaimableBatches
            ? maxClaimableBatches
            : _batchesCount;

        uint256[] memory claimableBatchNumbers = new uint256[](_batchesCount);
        for (uint256 i; i < _batchesCount; i++) {
            uint256 batchNumber = _claimableBatches[_nodeKeyId].at(
                unclaimedIndex
            );

            if (batchNumber > latestFinalizedBatchNumber) break;
            unclaimedIndex += 1;

            claimableBatchNumbers[i] = batchNumber;
        }

        nodeRewards.claimReward(_nodeKeyId, claimableBatchNumbers);
    }
}
