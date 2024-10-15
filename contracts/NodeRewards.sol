// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {NodeRewardsBase} from "./NodeRewardsBase.sol";
import {RewardsKYC} from "./RewardsKYC.sol";

contract NodeRewards is NodeRewardsBase, RewardsKYC {
    uint256 public immutable REWARD_PER_SECOND;
    uint256 public immutable MAX_REWARD_TIME_WINDOW;

    // batchNumber => reward per node key
    mapping(uint256 => uint256) public rewardPerNodeKeyOfBatch;

    constructor(
        uint256 _rewardPerSecond,
        uint256 _maxRewardTimeWindow,
        address _referee,
        address _nodeKey,
        address _rewardToken
    ) NodeRewardsBase(_referee, _nodeKey, _rewardToken) {
        _disableInitializers();
        REWARD_PER_SECOND = _rewardPerSecond;
        MAX_REWARD_TIME_WINDOW = _maxRewardTimeWindow;
    }

    function initialize(address _adminKycController) external initializer {
        __RewardsKYC_init(_adminKycController);
    }

    function _onAttest(uint256, uint256) internal pure override {
        return;
    }

    function _onFinalize(
        uint256 _batchNumber,
        uint256 _l1NodeConfirmedTimestamp,
        uint256 _prevL1NodeConfirmedTimestamp,
        uint256 _nrOfSuccessfulAttestations
    ) internal override {
        if (_nrOfSuccessfulAttestations > 0) {
            uint256 rewardTimeWindow = Math.min(
                _l1NodeConfirmedTimestamp - _prevL1NodeConfirmedTimestamp,
                MAX_REWARD_TIME_WINDOW
            );

            rewardPerNodeKeyOfBatch[_batchNumber] =
                (rewardTimeWindow * REWARD_PER_SECOND) /
                _nrOfSuccessfulAttestations;
        }
    }

    function _claimReward(
        uint256 _nodeKeyId,
        uint256[] calldata _batchNumbers
    ) internal override {
        uint256 reward;

        for (uint256 i; i < _batchNumbers.length; i++) {
            uint256 batchNumber = _batchNumbers[i];

            if (batchNumber != 0) {
                reward += rewardPerNodeKeyOfBatch[batchNumber];
            }
        }

        address nodeKeyOwner = NODE_KEY.ownerOf(_nodeKeyId);

        _onlyKycWallet(nodeKeyOwner);
        _payReward(nodeKeyOwner, reward);
    }
}
