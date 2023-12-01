// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ModuleManager.sol";
import "sentinellist/SentinelList.sol";
import "../interfaces/IMSA.sol";
import "../interfaces/IModule.sol";

abstract contract HookManager is ModuleManager, IMSA_ConfigExt {
    using SentinelListLib for SentinelListLib.SentinelList;

    IHook public _hook;

    function enableHook(address hook, bytes calldata data) external onlyEntryPoint {
        _hook = IHook(hook);
        emit EnableHook(hook);
    }

    function disableHook(address hook, bytes calldata data) external onlyEntryPoint {
        _hook = IHook(address(0));
        emit DisableHook(hook);
    }

    function isHookEnabled(address hook) external view returns (bool isEnabled) {
        return address(_hook) == hook;
    }
}
