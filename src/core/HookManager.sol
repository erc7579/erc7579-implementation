// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ModuleManager.sol";
import "../interfaces/IMSA.sol";
import "../interfaces/IModule.sol";

/**
 * @title HookManager
 * @dev This contract manages the hook module for the MSA
 * @author zeroknots.eth | rhinestone.wtf
 */
abstract contract HookManager is ModuleManager, IMSA_ConfigExt {
    IHook public _hook;

    /**
     * @inheritdoc IMSA_ConfigExt
     */
    function enableHook(address hook, bytes calldata data) external onlyEntryPoint {
        IHook(hook).enable(data);
        _hook = IHook(hook);
        emit EnableHook(hook);
    }

    /**
     * @inheritdoc IMSA_ConfigExt
     */
    function disableHook(address hook, bytes calldata data) external onlyEntryPoint {
        IHook(hook).disable(data);
        _hook = IHook(address(0));
        emit DisableHook(hook);
    }

    /**
     * @inheritdoc IMSA_ConfigExt
     */
    function isHookEnabled(address hook) external view returns (bool isEnabled) {
        return address(_hook) == hook;
    }
}
