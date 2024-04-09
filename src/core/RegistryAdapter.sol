// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../interfaces/IERC7484.sol";

abstract contract RegistryAdapter {
    event ERC7484RegistryConfigured(address indexed smartAccount, address indexed registry);

    IERC7484 internal $registry;

    modifier withRegistry(address module, uint256 moduleTypeId) {
        IERC7484 registry = $registry;
        if (address(registry) != address(0)) {
            registry.check(module, moduleTypeId);
        }
        _;
    }

    function setRegistry(
        IERC7484 registry,
        address[] calldata attesters,
        uint8 threshold
    )
        external
    {
        $registry = registry;
        if (attesters.length > 0) {
            registry.trustAttesters(threshold, attesters);
        }
    }
}
