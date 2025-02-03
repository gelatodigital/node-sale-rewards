// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    AccessControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract RewardsKYC is AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    error OnlyKycWallet();

    event LogSetKycDisabled(bool _disabled);

    bytes32 public constant ADMIN_KYC_CONTROLLER_ROLE =
        keccak256("ADMIN_KYC_CONTROLLER_ROLE");
    bytes32 public constant KYC_CONTROLLER_ROLE =
        keccak256("KYC_CONTROLLER_ROLE");
    bool public kycDisabled;
    EnumerableSet.AddressSet internal _kycWallets;

    function __RewardsKYC_init(
        address _adminKycController
    ) internal onlyInitializing {
        _setRoleAdmin(KYC_CONTROLLER_ROLE, ADMIN_KYC_CONTROLLER_ROLE);
        _grantRole(ADMIN_KYC_CONTROLLER_ROLE, _adminKycController);
    }

    function setKycDisabled(
        bool _disabled
    ) external onlyRole(KYC_CONTROLLER_ROLE) {
        kycDisabled = _disabled;

        emit LogSetKycDisabled(_disabled);
    }

    function addKycWallets(
        address[] calldata _wallets
    ) external onlyRole(KYC_CONTROLLER_ROLE) {
        for (uint256 i; i < _wallets.length; i++) {
            _kycWallets.add(_wallets[i]);
        }
    }

    function removeKycWallets(
        address[] calldata _wallets
    ) external onlyRole(KYC_CONTROLLER_ROLE) {
        for (uint256 i; i < _wallets.length; i++) {
            _kycWallets.remove(_wallets[i]);
        }
    }

    function getKycWallets() external view returns (address[] memory) {
        return _kycWallets.values();
    }

    function isKycWallet(address _wallet) external view returns (bool) {
        return _isKycWallet(_wallet);
    }

    function _isKycWallet(address _wallet) internal view returns (bool) {
        return _kycWallets.contains(_wallet);
    }

    function _onlyKycWallet(address _wallet) internal view {
        if (!kycDisabled && !_isKycWallet(_wallet)) {
            revert OnlyKycWallet();
        }
    }
}
