// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract RewardsHelper {
    error ETHTransferFailed();

    address private constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable REWARD_TOKEN;

    constructor(address _rewardToken) {
        REWARD_TOKEN = _rewardToken;
    }

    function _payReward(address _to, uint256 _amount) internal {
        if (REWARD_TOKEN == _ETH) {
            (bool success, ) = _to.call{value: _amount}("");
            if (!success) {
                revert ETHTransferFailed();
            }
        } else {
            SafeERC20.safeTransfer(IERC20(REWARD_TOKEN), _to, _amount);
        }
    }
}
