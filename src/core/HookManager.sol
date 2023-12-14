// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ModuleManager.sol";
import "../interfaces/IMSA.sol";
import "../interfaces/IModule.sol";
/**
 * @title reference implementation of the minimal modular smart account with Hook Extension
 * @author zeroknots.eth | rhinestone.wtf
 */

abstract contract HookManager is ModuleManager, IAccountConfig_Hook {
    /// @custom:storage-location erc7201:hookmanager.storage.msa
    struct HookManagerStorage {
        IHook _hook;
    }

    // keccak256("hookmanager.storage.msa");
    bytes32 constant HOOKMANAGER_STORAGE_LOCATION =
        0x36e05829dd1b9a4411d96a3549582172d7f071c1c0db5c573fcf94eb28431608;

    error HookPostCheckFailed();

    function _setHook(address hook) internal virtual {
        bytes32 slot = HOOKMANAGER_STORAGE_LOCATION;
        assembly {
            sstore(slot, hook)
        }
    }

    /**
     * @inheritdoc IAccountConfig_Hook
     */
    function installHook(address hook, bytes calldata data) public virtual onlyEntryPointOrSelf {
        _installHook(hook, data);
    }

    function _installHook(address hook, bytes calldata data) internal virtual {
        IHook(hook).onInstall(data);
        _setHook(hook);
        emit EnableHook(hook);
    }

    /**
     * @inheritdoc IAccountConfig_Hook
     */
    function uninstallHook(address hook, bytes calldata data) public virtual onlyEntryPointOrSelf {
        _uninstallHook(hook, data);
    }

    function _uninstallHook(address hook, bytes calldata data) internal virtual {
        IHook(hook).onUninstall(data);
        _setHook(address(0));
        emit DisableHook(hook);
    }

    /**
     * @inheritdoc IAccountConfig_Hook
     */
    function isHookEnabled(address hook) public view virtual returns (bool isEnabled) {
        address _hook;
        bytes32 slot = HOOKMANAGER_STORAGE_LOCATION;
        assembly {
            _hook := sload(slot)
        }

        return _hook == hook;
    }

    function supportsInterface(bytes4 interfaceID) public pure virtual override returns (bool) {
        if (interfaceID == type(IAccountConfig_Hook).interfaceId) return true;
        if (interfaceID == IAccountConfig_Hook.installHook.selector) return true;
        if (interfaceID == IAccountConfig_Hook.uninstallHook.selector) return true;
        if (interfaceID == IAccountConfig_Hook.isHookEnabled.selector) return true;
        return super.supportsInterface(interfaceID);
    }
}
