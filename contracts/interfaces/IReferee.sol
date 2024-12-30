// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {INodeKey} from "./INodeKey.sol";
import {INodeRewards} from "./INodeRewards.sol";
interface IReferee {
    struct BatchInfo {
        uint256 prevBatchNumber;
        uint256 l1NodeConfirmedTimestamp;
        uint256 nrOfSuccessfulAttestations;
        bytes32 finalL2StateRoot;
    }

    event LogAttest(
        uint256 _batchNumber,
        bytes32 _l2StateRoot,
        uint256 _nodeKeyId
    );
    event LogSetNodeRewards(address _nodeRewards);
    event LogSetNodeKey(address _nodeKey);
    event LogSetAttestPeriod(uint256 _attestPeriod);
    event LogSetOracle(address _oracle, bool _isOracle);
    event LogFinalized(
        uint256 _batchNumber,
        bytes32 _finalL2StateRoot,
        uint256 _nrOfSuccessfulAttestations
    );

    error AttestFailed();
    error InvalidBatchNumber();
    error NodeRewardsNotSet();
    error NoRewardsToClaim();
    error OnlyOracle();

    //solhint-disable-next-line func-name-mixedcase
    function ATTEST_PERIOD() external view returns (uint256 _attestPeriod);

    function nodeKey() external view returns (INodeKey _nodeKey);

    function nodeRewards() external view returns (INodeRewards _nodeRewards);

    function getBatchInfo(
        uint256 _batchNumber
    ) external view returns (BatchInfo memory);

    function getAttestedBatchNumbers(
        uint256 _nodeKeyId
    ) external view returns (uint256[] memory);

    function getIndexOfUnclaimedBatch(
        uint256 _nodeKeyId
    ) external view returns (uint256);

    function getAttestation(
        uint256 _batchNumber,
        uint256 _nodeKeyId
    ) external view returns (bytes32);

    function attest(
        uint256 _batchNumber,
        bytes32 _l2StateRoot,
        uint256 _nodeKeyId
    ) external;

    function batchAttest(
        uint256 _batchNumber,
        bytes32 _l2StateRoot,
        uint256[] memory _nodeKeyIds
    ) external;

    function finalize(
        uint256 _batchNumber,
        uint256 _l1NodeConfirmedTimestamp,
        bytes32 _finalL2StateRoot
    ) external;

    function claimReward(uint256 _nodeKeyId, uint256 _batchesCount) external;

    function batchClaimReward(
        uint256[] memory _nodeKeyIds,
        uint256 _batchesCount
    ) external;

    function getUnattestedNodeKeyIds(
        uint256 _batchNumber,
        uint256[] memory _nodeKeyIds
    ) external view returns (uint256[] memory);
}
