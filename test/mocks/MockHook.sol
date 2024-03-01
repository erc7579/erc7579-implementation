// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IHook, MODULE_TYPE_HOOK } from "src/interfaces/IERC7579Module.sol";

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

    function isModuleType(uint256 moduleTypeId) external view returns (bool) {
        return moduleTypeId == MODULE_TYPE_HOOK;
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        return false;
    }
}
