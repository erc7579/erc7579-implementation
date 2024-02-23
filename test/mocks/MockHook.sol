// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IHook, EncodedModuleTypes } from "src/interfaces/IERC7579Module.sol";

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
    function postCheck(bytes calldata hookData) external { }

    function isModuleType(uint256 typeID) external view returns (bool) {
        return typeID == 4;
    }

    function getModuleTypes() external view returns (EncodedModuleTypes) { }

    function isInitialized(address smartAccount) external view returns (bool) {
        return false;
    }
}
