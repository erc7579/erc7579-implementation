// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IHook } from "src/interfaces/IModule.sol";

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
}
