// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ModuleManager.sol";
import "../interfaces/IERC7579Account.sol";
import "../interfaces/IERC7579Module.sol";
/**
 * @title reference implementation of HookManager
 * @author zeroknots.eth | rhinestone.wtf
 */

abstract contract HookManager {
    /// @custom:storage-location erc7201:hookmanager.storage.msa
    struct HookManagerStorage {
        IHook _hook;
    }

    // keccak256("hookmanager.storage.msa");
    bytes32 constant HOOKMANAGER_STORAGE_LOCATION =
        0x36e05829dd1b9a4411d96a3549582172d7f071c1c0db5c573fcf94eb28431608;

    error HookpostCheckFailed();
    error HookAlreadyInstalled(address currentHook);

    modifier executionHook(ModeCode mode, bytes calldata executionCalldata) {
        address hook = _getHook();
        if (hook == address(0)) {
            _;
        } else {
            bytes memory precheckcontext =
                IHook(hook).executionPreCheck(msg.sender, mode, executionCalldata);
            _;
            if (IHook(hook).postCheck(precheckcontext) == false) {
                revert HookpostCheckFailed();
            }
        }
    }

    modifier executionUserOpHook(PackedUserOperation calldata userOp) {
        address hook = _getHook();
        if (hook == address(0)) {
            _;
        } else {
            bytes memory precheckcontext = IHook(hook).executionPreCheck(msg.sender, userOp);
            _;
            if (IHook(hook).postCheck(precheckcontext) == false) {
                revert HookpostCheckFailed();
            }
        }
    }

    modifier installationHook(uint256 moduleType, address module, bytes calldata initData) {
        address hook = _getHook();
        if (hook == address(0)) {
            _;
        } else {
            bytes memory preCheckContext =
                IHook(hook).installationPreCheck(msg.sender, moduleType, module, initData);
            _;
            if (IHook(hook).postCheck(preCheckContext) == false) {
                revert HookpostCheckFailed();
            }
        }
    }

    modifier uninstallationHook(uint256 moduleType, address module, bytes calldata initData) {
        address hook = _getHook();
        if (hook == address(0)) {
            _;
        } else {
            bytes memory preCheckContext =
                IHook(hook).uninstallationPreCheck(msg.sender, moduleType, module, initData);
            _;
            if (IHook(hook).postCheck(preCheckContext) == false) {
                revert HookpostCheckFailed();
            }
        }
    }

    modifier fallbackHook(address fallbackHandler, bytes calldata msgData) {
        address hook = _getHook();
        if (hook == address(0)) {
            _;
        } else {
            bytes memory preCheckContext =
                IHook(hook).fallbackPreCheck(msg.sender, fallbackHandler, msgData);
            _;
            if (IHook(hook).postCheck(preCheckContext) == false) {
                revert HookpostCheckFailed();
            }
        }
    }

    function _setHook(address hook) internal virtual {
        bytes32 slot = HOOKMANAGER_STORAGE_LOCATION;
        assembly {
            sstore(slot, hook)
        }
    }

    function _installHook(address hook, bytes calldata data) internal virtual {
        address currentHook = _getHook();
        if (currentHook != address(0)) {
            revert HookAlreadyInstalled(currentHook);
        }
        _setHook(hook);
        IHook(hook).onInstall(data);
    }

    function _uninstallHook(address hook, bytes calldata data) internal virtual {
        _setHook(address(0));
        IHook(hook).onUninstall(data);
    }

    function _getHook() internal view returns (address _hook) {
        bytes32 slot = HOOKMANAGER_STORAGE_LOCATION;
        assembly {
            _hook := sload(slot)
        }
    }

    function _isHookInstalled(address module) internal view returns (bool) {
        return _getHook() == module;
    }

    function getActiveHook() external view returns (address hook) {
        return _getHook();
    }
}
