// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Proxied} from "../vendor/proxy/Proxied.sol";

contract MockRewardToken is ERC20Upgradeable, Proxied {
    function initialize(
        string memory _name,
        string memory _symbol
    ) external initializer {
        __ERC20_init(_name, _symbol);
    }

    function mint(address _account, uint256 _value) external onlyProxyAdmin {
        _mint(_account, _value);
    }

    function burn(address _account, uint256 _value) external onlyProxyAdmin {
        _burn(_account, _value);
    }
}
