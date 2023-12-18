// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC7484Registry {
    function check(address executor, address attester) external view returns (uint256 listedAt);

    function checkN(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray);
}

/**
 * @title native registry adapter for smart accounts
 * @author @kopy-kat | rhinestone.wtf
 */
abstract contract RegistryAdapter {
    // Instance of the IRegistry contract
    IERC7484Registry registry;
    address trustedAttester;

    function setRegistry(IERC7484Registry _registry) external {
        registry = _registry;
    }

    modifier onlySecureModule(address module) {
        _enforceRegistryCheck(module);
        _;
    }

    function getAttester() public view virtual returns (address attester) {
        attester = trustedAttester;
    }

    function _setAttester(address attester) internal {
        trustedAttester = attester;
    }

    function _enforceRegistryCheck(address module) internal view virtual {
        registry.check(module, trustedAttester);
    }

    event TrustedAttesterSet(address indexed account, address indexed attester);
}
