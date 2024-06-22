// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC7484 } from "../interfaces/IERC7484.sol";
import { AccountBase } from "./AccountBase.sol";

/**
 * @title RegistryAdapter
 * @author kopy-kat | rhinestone.wtf
 * @dev This contract uses ERC-7484 to check if a module is attested to and exposes a modifier to
 * use it.
 */
abstract contract RegistryAdapter is AccountBase {
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
        onlyEntryPointOrSelf
    {
        $registry = registry;
        if (attesters.length > 0) {
            registry.trustAttesters(threshold, attesters);
        }
    }
}
