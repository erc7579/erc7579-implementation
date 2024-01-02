// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {
    IValidator, IERC4337, VALIDATION_SUCCESS, VALIDATION_FAILED
} from "src/interfaces/IModule.sol";
import { ECDSA } from "solady/utils/ECDSA.sol";

contract ECDSAValidator is IValidator {
    using ECDSA for bytes32;

    mapping(address => address) public owners;

    function setOwner(address owner) external {
        owners[msg.sender] = owner;
    }

    function onInstall(bytes calldata data) external override {
        address owner = address(bytes20(data));
        owners[msg.sender] = owner;
    }

    function onUninstall(bytes calldata data) external override {
        delete owners[msg.sender];
    }

    function validateUserOp(
        IERC4337.UserOperation calldata userOp,
        bytes32 userOpHash
    )
        external
        override
        returns (uint256)
    {
        bytes32 hash = userOpHash.toEthSignedMessageHash();

        if (owners[msg.sender] != hash.recover(userOp.signature)) {
            return VALIDATION_FAILED;
        }
        return VALIDATION_SUCCESS;
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        override
        returns (bytes4)
    { }

    function isModuleType(uint256 typeID) external view returns (bool) {
        return typeID == 1;
    }
}
