// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {INodeKey} from "./interfaces/INodeKey.sol";
import {IReferee} from "./interfaces/IReferee.sol";
import {RewardsHelper} from "./RewardsHelper.sol";

abstract contract NodeRewardsBase is RewardsHelper {
    error OnlyReferee();

    IReferee public immutable REFEREE;
    INodeKey public immutable NODE_KEY;

    modifier onlyReferee() {
        if (msg.sender != address(REFEREE)) {
            revert OnlyReferee();
        }
        _;
    }

    receive() external payable {}

    constructor(
        address _referee,
        address _nodeKey,
        address _rewardToken
    ) RewardsHelper(_rewardToken) {
        REFEREE = IReferee(_referee);
        NODE_KEY = INodeKey(_nodeKey);
    }

    /**
     * @notice Called in Referee.attest whenever an attestation is submitted. {See Referee.sol}
     *
     * @param _batchNumber Batch number of the attestation.
     * @param _nodeKeyId Id of the node key.
     */
    function onAttest(
        uint256 _batchNumber,
        uint256 _nodeKeyId
    ) external onlyReferee {
        _onAttest(_batchNumber, _nodeKeyId);
    }

    /**
     * @notice Called in Referee.batchAttest whenever multiple attestations are submitted. {See Referee.sol}
     *
     * @param _batchNumber Batch number of the attestation.
     * @param _nodeKeyIds Id of the node keys.
     *
     * @dev _nodeKeyIds can contain 0 (empty items). We skip over it here.
     */
    function onBatchAttest(
        uint256 _batchNumber,
        uint256[] calldata _nodeKeyIds
    ) external onlyReferee {
        for (uint256 i; i < _nodeKeyIds.length; i++) {
            if (_nodeKeyIds[i] == 0) continue;
            _onAttest(_batchNumber, _nodeKeyIds[i]);
        }
    }

    /**
     * @notice Called in Referee.finalize whenever attestations of a batch are finalized. {See Referee.sol}
     *
     * @param _batchNumber Batch number that is being finalized.
     * @param _l1NodeConfirmedTimestamp Timestamp of which the batch is confirmed on the L1.
     * @param _prevL1NodeConfirmedTimestamp Timestamp of which the previous batch is confirmed on the L1.
     * @param _nrOfSuccessfulAttestations Number of node keys which have submitted a valid attestation.
     *
     * @dev _prevL1NodeConfirmedTimestamp can be 0 when _batchNumber is the first ever batch being finalized.
     */
    function onFinalize(
        uint256 _batchNumber,
        uint256 _l1NodeConfirmedTimestamp,
        uint256 _prevL1NodeConfirmedTimestamp,
        uint256 _nrOfSuccessfulAttestations
    ) external onlyReferee {
        _onFinalize(
            _batchNumber,
            _l1NodeConfirmedTimestamp,
            _prevL1NodeConfirmedTimestamp,
            _nrOfSuccessfulAttestations
        );
    }

    /**
     * @notice Called in Referee.claimReward whenever someone claims their reward. {See Referee.sol}
     *
     * @param _nodeKeyId Id of the node key which is claiming the reward.
     * @param _batchNumbers Batch numbers of successful attestations made by the node key.
     *
     * @dev _batchNumbers can contain 0 (empty items). Make sure to skip over it.
     */
    function claimReward(
        uint256 _nodeKeyId,
        uint256[] calldata _batchNumbers
    ) external onlyReferee {
        _claimReward(_nodeKeyId, _batchNumbers);
    }

    /**
     * @dev Override this function if your rewards logic for each
     * node key varies depending on other factor.
     *
     * @param _batchNumber Batch number of the attestation.
     * @param _nodeKeyId Id of the node key.
     */
    function _onAttest(
        uint256 _batchNumber,
        uint256 _nodeKeyId
    ) internal virtual;

    /**
     * @dev Override this function if your rewards logic takes into
     * account the timestamps of the attestation and number of attestations.
     *
     * @dev IMPORTANT _prevL1NodeConfirmedTimestamp can be 0 when _batchNumber is the first ever batch being finalized.
     *
     * @param _batchNumber Batch number that is being finalized.
     * @param _l1NodeConfirmedTimestamp Timestamp of which the batch is confirmed on the L1.
     * @param _prevL1NodeConfirmedTimestamp Timestamp of which the previous batch is confirmed on the L1.
     * @param _nrOfSuccessfulAttestations Number of node keys which have submitted a valid attestation.
     */
    function _onFinalize(
        uint256 _batchNumber,
        uint256 _l1NodeConfirmedTimestamp,
        uint256 _prevL1NodeConfirmedTimestamp,
        uint256 _nrOfSuccessfulAttestations
    ) internal virtual;

    /**
     * @dev Override this function to handle the reward payment logic.
     *
     * @dev IMPORTANT _batchNumbers can contain 0 (empty items). Make sure to skip over it.
     *
     * @param _nodeKeyId Id of the node key which is claiming the reward.
     * @param _batchNumbers Batch numbers of successful attestations made by the node key.
     */
    function _claimReward(
        uint256 _nodeKeyId,
        uint256[] calldata _batchNumbers
    ) internal virtual;
}
