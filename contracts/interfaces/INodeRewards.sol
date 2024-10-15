// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface INodeRewards {
    function claimReward(
        uint256 _nodeKeyId,
        uint256[] calldata _batchNumbers
    ) external;

    function onAttest(uint256 _batchNumber, uint256 _nodeKeyId) external;

    function onBatchAttest(
        uint256 _batchNumber,
        uint256[] calldata _nodeKeyIds
    ) external;

    function onFinalize(
        uint256 _batchNumber,
        uint256 _l1NodeConfirmedTimestamp,
        uint256 _prevL1NodeConfirmedTimestamp,
        uint256 _nrOfSuccessfulAttestations
    ) external;
}
