// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ModuleManager.sol";
import "../interfaces/IMSA.sol";
import "../interfaces/IModule.sol";

abstract contract HookManager is ModuleManager, IMSA_ConfigExt {
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
     * @inheritdoc IMSA_ConfigExt
     */
    function enableHook(address hook, bytes calldata data) public virtual onlyEntryPointOrSelf {
        _enableHook(hook, data);
    }

    function _enableHook(address hook, bytes calldata data) internal virtual {
        IHook(hook).enable(data);
        _setHook(hook);
        emit EnableHook(hook);
    }

    /**
     * @inheritdoc IMSA_ConfigExt
     */
    function disableHook(address hook, bytes calldata data) public virtual onlyEntryPointOrSelf {
        _disableHook(hook, data);
    }

    function _disableHook(address hook, bytes calldata data) internal virtual {
        IHook(hook).disable(data);
        _setHook(address(0));
        emit DisableHook(hook);
    }

    /**
     * @inheritdoc IMSA_ConfigExt
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
        if (interfaceID == type(IMSA_ConfigExt).interfaceId) return true;
        return super.supportsInterface(interfaceID);
    }
}
