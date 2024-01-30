// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IHook } from "src/interfaces/IERC7579Module.sol";

contract MockHook is IHook {
    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function preCheck(
        address msgSender,
        uint256 msdValue,
        bytes calldata msgData
    )
        external
        returns (bytes memory hookData)
    { }
    function postCheck(bytes calldata hookData) external returns (bool success) { }

    function isModuleType(uint256 typeID) external pure returns (bool) {
        return typeID == 4;
    }

    function getModuleTypes() external pure returns (uint256) {
        return 1 << 4;
    }

    function isInitialized(address smartAccount) external pure returns (bool) {
        return false;
    }
}
