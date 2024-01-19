// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {SentinelListLib, SENTINEL} from "sentinellist/SentinelList.sol";
import {AccountBase} from "./AccountBase.sol";
import {IValidator, IExecutor} from "../interfaces/IModule.sol";
import "forge-std/interfaces/IERC165.sol";

/**
 * @title ModuleManager
 * @author zeroknots.eth | rhinestone.wtf
 * @dev This contract manages Validator and Executor modules for the MSA
 * @dev it uses SentinelList to manage the linked list of modules
 */
abstract contract ModuleManager is AccountBase {
    using SentinelListLib for SentinelListLib.SentinelList;

    error InvalidModule(address module);
    error CannotRemoveLastValidator();

    /// @custom:storage-location erc7201:modulemanager.storage.msa
    struct ModuleManagerStorage {
        // linked list of validators. List is initialized by initializeAccount()
        SentinelListLib.SentinelList _validators;
        // linked list of executors. List is initialized by initializeAccount()
        SentinelListLib.SentinelList _executors;
    }

    // keccak256("modulemanager.storage.msa");
    bytes32 constant MODULEMANAGER_STORAGE_LOCATION = 0xf88ce1fdb7fb1cbd3282e49729100fa3f2d6ee9f797961fe4fb1871cea89ea02;

    function _getModuleManagerStorage() internal pure virtual returns (ModuleManagerStorage storage ims) {
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

    function _installValidator(address validator, bytes calldata data) internal virtual {
        SentinelListLib.SentinelList storage _validators = _getModuleManagerStorage()._validators;
        IValidator(validator).onInstall(data);
        _validators.push(validator);
    }

    function isValidatorInstalled(address validator) internal view virtual returns (bool) {
        SentinelListLib.SentinelList storage _validators = _getModuleManagerStorage()._validators;
        return _validators.contains(validator);
    }

    /**
     * THIS IS NOT PART OF THE STANDARD
     * Helper Function to access linked list
     */
    function getValidatorPaginated(address cursor, uint256 size)
        external
        view
        virtual
        returns (address[] memory array, address next)
    {
        SentinelListLib.SentinelList storage _validators = _getModuleManagerStorage()._validators;
        return _validators.getEntriesPaginated(cursor, size);
    }

    function _installExecutor(address executor, bytes calldata data) internal {
        SentinelListLib.SentinelList storage _executors = _getModuleManagerStorage()._executors;
        IExecutor(executor).onInstall(data);
        _executors.push(executor);
    }

    /**
     * THIS IS NOT PART OF THE STANDARD
     * Helper Function to access linked list
     */
    function getExecutorsPaginated(address cursor, uint256 size)
        external
        view
        virtual
        returns (address[] memory array, address next)
    {
        SentinelListLib.SentinelList storage _executors = _getModuleManagerStorage()._executors;
        return _executors.getEntriesPaginated(cursor, size);
    }

    function isAlreadyInitialized() internal view virtual returns (bool) {
        ModuleManagerStorage storage ims = _getModuleManagerStorage();
        return ims._validators.alreadyInitialized();
    }
}
