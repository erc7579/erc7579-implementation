// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {
    IValidator,
    PackedUserOperation,
    VALIDATION_SUCCESS,
    MODULE_TYPE_VALIDATOR
} from "src/interfaces/IERC7579Module.sol";

contract MockValidator is IValidator {
    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function validateUserOp(
        PackedUserOperation calldata, // userOp
        bytes32 // userOpHash
    )
        external
        pure
        override
        returns (uint256)
    {
        return VALIDATION_SUCCESS;
    }

    function isValidSignatureWithSender(
        address, // sender
        bytes32, // hash
        bytes calldata // signature
    )
        external
        pure
        override
        returns (bytes4)
    {
        return 0x1626ba7e;
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function isInitialized(address)
        // smartAccount
        external
        pure
        returns (bool)
    {
        return false;
    }
}
