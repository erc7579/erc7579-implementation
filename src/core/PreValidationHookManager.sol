// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ModuleManager.sol";
import "../interfaces/IERC7579Account.sol";
import "../interfaces/IERC7579Module.sol";

/**
 * @title reference implementation of PreValidationHookManager
 * @author highskore | rhinestone.wtf
 */
abstract contract PreValidationHookManager {
    event PreValidationHookUninstallFailed(address hook, bytes data);

    error InvalidHookType();

    /// @custom:storage-location erc7201:prevalidationhookmanager.storage.msa
    struct PreValidationHookManagerStorage {
        IPreValidationHookERC1271 hook1271;
        IPreValidationHookERC4337 hook4337;
    }

    // forgefmt: disable-next-line
    // keccak256(abi.encode(uint256(keccak256("prevalidationhookmanager.storage.msa")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 constant PREVALIDATION_HOOKMANAGER_STORAGE_LOCATION =
        0x088e45215d3756b04bd240e41d75700a696139d5b53082481ffc3914e4840000;

    error PreValidationHookAlreadyInstalled(address currentHook);

    function _getStorage()
        internal
        pure
        returns (PreValidationHookManagerStorage storage storage_)
    {
        bytes32 slot = PREVALIDATION_HOOKMANAGER_STORAGE_LOCATION;
        assembly {
            storage_.slot := slot
        }
    }

    function _setPreValidationHook(address hook, uint256 hookType) internal virtual {
        PreValidationHookManagerStorage storage $ = _getStorage();
        if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271) {
            $.hook1271 = IPreValidationHookERC1271(hook);
        } else if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337) {
            $.hook4337 = IPreValidationHookERC4337(hook);
        } else {
            revert InvalidHookType();
        }
    }

    function _installPreValidationHook(
        address hook,
        uint256 hookType,
        bytes calldata data
    )
        internal
        virtual
    {
        PreValidationHookManagerStorage storage $ = _getStorage();
        address currentHook = _getPreValidationHook(hookType);
        if (currentHook != address(0)) {
            revert PreValidationHookAlreadyInstalled(currentHook);
        }
        _setPreValidationHook(hook, hookType);
        if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271) {
            $.hook1271.onInstall(data);
        } else if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337) {
            $.hook4337.onInstall(data);
        }
    }

    function _uninstallPreValidationHook(
        address hook,
        uint256 hookType,
        bytes calldata data
    )
        internal
        virtual
    {
        PreValidationHookManagerStorage storage $ = _getStorage();
        if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271 && address($.hook1271) == hook) {
            $.hook1271.onUninstall(data);
        } else if (
            hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337 && address($.hook4337) == hook
        ) {
            $.hook4337.onUninstall(data);
        } else {
            revert InvalidHookType();
        }
        _setPreValidationHook(address(0), hookType);
    }

    function _tryUninstallPreValidationHook(address hook, uint256 hookType) internal virtual {
        PreValidationHookManagerStorage storage $ = _getStorage();
        if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271) {
            try $.hook1271.onUninstall("") { }
            catch {
                emit PreValidationHookUninstallFailed(hook, "");
            }
            $.hook1271 = IPreValidationHookERC1271(address(0));
        } else if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337) {
            try $.hook4337.onUninstall("") { }
            catch {
                emit PreValidationHookUninstallFailed(hook, "");
            }
            $.hook4337 = IPreValidationHookERC4337(address(0));
        } else {
            revert InvalidHookType();
        }
    }

    function _getPreValidationHook(uint256 hookType) internal view returns (address _hook) {
        PreValidationHookManagerStorage storage $ = _getStorage();
        if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271) {
            return address($.hook1271);
        } else if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337) {
            return address($.hook4337);
        } else {
            revert InvalidHookType();
        }
    }

    function _isPreValidationHookInstalled(
        address module,
        uint256 hookType
    )
        internal
        view
        returns (bool)
    {
        return _getPreValidationHook(hookType) == module;
    }

    function getActiveHook(uint256 hookType) external view returns (address hook) {
        return _getPreValidationHook(hookType);
    }

    function _withPreValidationHook(
        bytes32 hash,
        bytes calldata signature
    )
        internal
        view
        virtual
        returns (bytes32 postHash, bytes memory postSig)
    {
        address preValidationHook = _getPreValidationHook(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271);
        if (preValidationHook == address(0)) {
            return (hash, signature);
        } else {
            return IPreValidationHookERC1271(preValidationHook).preValidationHookERC1271(
                msg.sender, hash, signature
            );
        }
    }

    function _withPreValidationHook(
        bytes32 hash,
        PackedUserOperation memory userOp,
        uint256 missingAccountFunds
    )
        internal
        virtual
        returns (bytes32 postHash, bytes memory postSig)
    {
        address preValidationHook = _getPreValidationHook(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337);
        if (preValidationHook == address(0)) {
            return (hash, userOp.signature);
        } else {
            return IPreValidationHookERC4337(preValidationHook).preValidationHookERC4337(
                userOp, missingAccountFunds, hash
            );
        }
    }
}
