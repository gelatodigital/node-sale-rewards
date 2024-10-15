// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {
    ERC721Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Proxied} from "./vendor/proxy/Proxied.sol";

contract NodeKey is ERC721Upgradeable, Proxied {
    error NonTransferable();

    uint256 public totalSupply;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol
    ) external initializer {
        __ERC721_init(_name, _symbol);
    }

    function mint(address _to, uint256 _amount) external onlyProxyAdmin {
        for (uint256 i; i < _amount; i++) {
            totalSupply += 1;

            _safeMint(_to, totalSupply);
        }
    }

    /**
     * @dev Overriden to disable transferFrom.
     */
    function _update(
        address _to,
        uint256 _tokenId,
        address _auth
    ) internal override returns (address) {
        address from = _ownerOf(_tokenId);

        // Only minting enabled
        if (from == address(0) && _to != address(0)) {
            super._update(_to, _tokenId, _auth);
        } else {
            revert NonTransferable();
        }

        return from;
    }
}
