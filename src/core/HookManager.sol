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
    event HookUninstallFailed(address hook, bytes data);

    /// @custom:storage-location erc7201:hookmanager.storage.msa
    struct HookManagerStorage {
        IHook _hook;
    }

    // forgefmt: disable-next-line
    // keccak256(abi.encode(uint256(keccak256("hookmanager.storage.msa")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 constant HOOKMANAGER_STORAGE_LOCATION =
        0xcd97a6611018468306afd07ac8b14141bc76df8b844b3bcba1768d81e4598200;

    error HookPostCheckFailed();
    error HookAlreadyInstalled(address currentHook);

    modifier withHook() {
        address hook = _getHook();
        if (hook == address(0)) {
            _;
        } else {
            bytes memory hookData = IHook(hook).preCheck(msg.sender, msg.value, msg.data);
            _;
            IHook(hook).postCheck(hookData);
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

    function _tryUninstallHook(address hook) internal virtual {
        if (hook != address(0)) {
            try IHook(hook).onUninstall("") { }
            catch {
                emit HookUninstallFailed(hook, "");
            }
            _setHook(address(0));
        }
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
