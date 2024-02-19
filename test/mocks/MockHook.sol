// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IHook, EncodedModuleTypes } from "src/interfaces/IERC7579Module.sol";
import { ModeCode } from "src/lib/ModeLib.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/IAccount.sol";

contract MockHook is IHook {
    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function preCheck(
        address msgSender,
        bytes calldata msgData
    )
        external
        returns (bytes memory hookData)
    { }

    function postCheck(bytes calldata hookData) external returns (bool success) { }

    function isModuleType(uint256 typeID) external view returns (bool) {
        return typeID == 4;
    }

    function getModuleTypes() external view returns (EncodedModuleTypes) { }

    function isInitialized(address smartAccount) external view returns (bool) {
        return false;
    }

    function executionPreCheck(
        address msgSender,
        ModeCode mode,
        bytes calldata executionCalldata
    )
        external
        override
        returns (bytes memory preCheckContext)
    { }

    function executionPreCheck(
        address msgSender,
        PackedUserOperation calldata userOp
    )
        external
        override
        returns (bytes memory preCheckContext)
    { }

    function installationPreCheck(
        address msgSender,
        uint256 moduleType,
        address module,
        bytes calldata initData
    )
        external
        override
        returns (bytes memory preCheckContext)
    { }

    function uninstallationPreCheck(
        address msgSender,
        uint256 moduleType,
        address module,
        bytes calldata initData
    )
        external
        override
        returns (bytes memory preCheckContext)
    { }

    function fallbackPreCheck(
        address msgSender,
        address fallbackHandler,
        bytes calldata msgData
    )
        external
        override
        returns (bytes memory preCheckContext)
    { }
}
