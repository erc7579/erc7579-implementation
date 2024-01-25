// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { SentinelListLib, SENTINEL } from "sentinellist/SentinelList.sol";
import { AccountBase } from "./AccountBase.sol";
import "../interfaces/IModule.sol";
import "forge-std/interfaces/IERC165.sol";

/**
 * @title ModuleManager
 * @author zeroknots.eth | rhinestone.wtf
 * @dev This contract manages Validator, Executor and Fallback modules for the MSA
 * @dev it uses SentinelList to manage the linked list of modules
 * NOTE: the linked list is just an example. accounts may implement this differently
 */
abstract contract ModuleManager is AccountBase {
    using SentinelListLib for SentinelListLib.SentinelList;

    error InvalidModule(address module);
    error CannotRemoveLastValidator();

    // keccak256("modulemanager.storage.msa");
    bytes32 constant MODULEMANAGER_STORAGE_LOCATION =
        0xf88ce1fdb7fb1cbd3282e49729100fa3f2d6ee9f797961fe4fb1871cea89ea02;

    /// @custom:storage-location erc7201:modulemanager.storage.msa
    struct ModuleManagerStorage {
        // linked list of validators. List is initialized by initializeAccount()
        SentinelListLib.SentinelList _validators;
        // linked list of executors. List is initialized by initializeAccount()
        SentinelListLib.SentinelList _executors;
        // single fallback handler for all fallbacks
        // account vendors may implement this differently. This is just a reference implementation
        address fallbackHandler;
    }

    function _getModuleManagerStorage()
        internal
        pure
        virtual
        returns (ModuleManagerStorage storage ims)
    {
        bytes32 position = MODULEMANAGER_STORAGE_LOCATION;
        assembly {
            ims.slot := position
        }
    }

    modifier onlyExecutorModule() {
        SentinelListLib.SentinelList storage _executors = _getModuleManagerStorage()._executors;
        if (!_executors.contains(msg.sender)) revert InvalidModule(msg.sender);
        _;
    }

    modifier onlyValidatorModule(address validator) {
        SentinelListLib.SentinelList storage _validators = _getModuleManagerStorage()._validators;
        if (!_validators.contains(validator)) revert InvalidModule(validator);
        _;
    }

    function _initModuleManager() internal virtual {
        ModuleManagerStorage storage ims = _getModuleManagerStorage();
        ims._executors.init();
        ims._validators.init();
    }

    function isAlreadyInitialized() internal view virtual returns (bool) {
        ModuleManagerStorage storage ims = _getModuleManagerStorage();
        return ims._validators.alreadyInitialized();
    }

    /////////////////////////////////////////////////////
    //  Manage Validators
    ////////////////////////////////////////////////////
    function _installValidator(address validator, bytes calldata data) internal virtual {
        SentinelListLib.SentinelList storage _validators = _getModuleManagerStorage()._validators;
        IValidator(validator).onInstall(data);
        _validators.push(validator);
    }

    function _uninstallValidator(address executor, bytes calldata data) internal {
        // TODO: check if its the last validator. this might brick the account
        SentinelListLib.SentinelList storage _validators = _getModuleManagerStorage()._executors;
        (address prev, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        IExecutor(executor).onUninstall(disableModuleData);
        _validators.pop(prev, executor);
    }

    function _isValidatorInstalled(address validator) internal view virtual returns (bool) {
        SentinelListLib.SentinelList storage _validators = _getModuleManagerStorage()._validators;
        return _validators.contains(validator);
    }

    /**
     * THIS IS NOT PART OF THE STANDARD
     * Helper Function to access linked list
     */
    function getValidatorPaginated(
        address cursor,
        uint256 size
    )
        external
        view
        virtual
        returns (address[] memory array, address next)
    {
        SentinelListLib.SentinelList storage _validators = _getModuleManagerStorage()._validators;
        return _validators.getEntriesPaginated(cursor, size);
    }

    /////////////////////////////////////////////////////
    //  Manage Executors
    ////////////////////////////////////////////////////

    function _installExecutor(address executor, bytes calldata data) internal {
        SentinelListLib.SentinelList storage _executors = _getModuleManagerStorage()._executors;
        IExecutor(executor).onInstall(data);
        _executors.push(executor);
    }

    function _uninstallExecutor(address executor, bytes calldata data) internal {
        SentinelListLib.SentinelList storage _executors = _getModuleManagerStorage()._executors;
        (address prev, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        IExecutor(executor).onUninstall(disableModuleData);
        _executors.pop(prev, executor);
    }

    function _isExecutorInstalled(address executor) internal view virtual returns (bool) {
        SentinelListLib.SentinelList storage _executors = _getModuleManagerStorage()._executors;
        return _executors.contains(executor);
    }

    /**
     * THIS IS NOT PART OF THE STANDARD
     * Helper Function to access linked list
     */
    function getExecutorsPaginated(
        address cursor,
        uint256 size
    )
        external
        view
        virtual
        returns (address[] memory array, address next)
    {
        SentinelListLib.SentinelList storage _executors = _getModuleManagerStorage()._executors;
        return _executors.getEntriesPaginated(cursor, size);
    }

    /////////////////////////////////////////////////////
    //  Manage Fallback
    ////////////////////////////////////////////////////

    function _installFallbackHandler(address handler, bytes calldata initData) internal virtual {
        if (_isFallbackHandlerInstalled()) revert();
        _getModuleManagerStorage().fallbackHandler = handler;
        IFallback(handler).onInstall(initData);
    }

    function _uninstallFallbackHandler(
        address fallbackHandler,
        bytes calldata initData
    )
        internal
        virtual
    {
        address currentFallback = _getModuleManagerStorage().fallbackHandler;
        if (currentFallback != fallbackHandler) revert InvalidModule(fallbackHandler);
        _getModuleManagerStorage().fallbackHandler = address(0);
        IFallback(currentFallback).onUninstall(initData);
    }

    function _isFallbackHandlerInstalled() internal view virtual returns (bool) {
        return _getModuleManagerStorage().fallbackHandler != address(0);
    }

    function _isFallbackHandlerInstalled(address _handler) internal view virtual returns (bool) {
        return _getModuleManagerStorage().fallbackHandler == _handler;
    }

    // FALLBACK
    fallback() external {
        address handler = _getModuleManagerStorage().fallbackHandler;
        if (handler == address(0)) revert();
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            // When compiled with the optimizer, the compiler relies on a certain assumptions on how
            // the
            // memory is used, therefore we need to guarantee memory safety (keeping the free memory
            // point 0x40 slot intact,
            // not going beyond the scratch space, etc)
            // Solidity docs: https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            let calldataPtr := allocate(calldatasize())
            calldatacopy(calldataPtr, 0, calldatasize())

            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            let senderPtr := allocate(20)
            mstore(senderPtr, shl(96, caller()))

            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, calldataPtr, add(calldatasize(), 20), 0, 0)

            let returnDataPtr := allocate(returndatasize())
            returndatacopy(returnDataPtr, 0, returndatasize())
            if iszero(success) { revert(returnDataPtr, returndatasize()) }
            return(returnDataPtr, returndatasize())
        }
        /* solhint-enable no-inline-assembly */
    }
}
