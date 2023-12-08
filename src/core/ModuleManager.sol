// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "sentinellist/SentinelList.sol";
import "./AccountBase.sol";
import "../interfaces/IMSA.sol";
import "../interfaces/IModule.sol";

abstract contract ModuleManager is AccountBase, IMSA_Config {
    using SentinelListLib for SentinelListLib.SentinelList;

    error InvalidModule(address module);

    /// @custom:storage-location erc7201:modulemanager.storage.msa
    struct ModuleManagerStorage {
        // linked list of validators. List is initialized by initializeAccount()
        SentinelListLib.SentinelList _validators;
        // linked list of executors. List is initialized by initializeAccount()
        SentinelListLib.SentinelList _executors;
    }

    // keccak256("modulemanager.storage.msa");
    bytes32 constant MODULEMANAGER_STORAGE_LOCATION =
        0xf88ce1fdb7fb1cbd3282e49729100fa3f2d6ee9f797961fe4fb1871cea89ea02;

    function _getModuleMangerStorage()
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
        SentinelListLib.SentinelList storage _executors = _getModuleMangerStorage()._executors;
        if (!_executors.contains(msg.sender)) revert InvalidModule(msg.sender);
        _;
    }

    modifier onlyValidatorModule(address validator) {
        SentinelListLib.SentinelList storage _validators = _getModuleMangerStorage()._validators;
        if (!_validators.contains(validator)) revert InvalidModule(validator);
        _;
    }

    function _initModuleManager() internal virtual {
        ModuleManagerStorage storage ims = _getModuleMangerStorage();
        ims._executors.init();
        ims._validators.init();
    }

    /**
     * @inheritdoc IMSA_Config
     */
    function enableValidator(
        address validator,
        bytes calldata data
    )
        public
        virtual
        override
        onlyEntryPointOrSelf
    {
        _enableValidator(validator, data);
    }

    function _enableValidator(address validator, bytes calldata data) internal virtual {
        SentinelListLib.SentinelList storage _validators = _getModuleMangerStorage()._validators;
        IValidator(validator).enable(data);
        _validators.push(validator);
        emit EnableValidator(validator);
    }

    /**
     * @inheritdoc IMSA_Config
     */
    function disableValidator(
        address validator,
        bytes calldata data
    )
        external
        override
        onlyEntryPointOrSelf
    {
        SentinelListLib.SentinelList storage _validators = _getModuleMangerStorage()._validators;
        // decode prev validator cause this is a linked list (optional)
        (address prevValidator, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        IValidator(validator).disable(disableModuleData);
        _validators.pop(prevValidator, validator);
        emit DisableValidator(validator);
    }

    /**
     * @inheritdoc IMSA_Config
     */
    function isValidatorEnabled(address validator) public view virtual returns (bool) {
        SentinelListLib.SentinelList storage _validators = _getModuleMangerStorage()._validators;
        return _validators.contains(validator);
    }

    /**
     * @inheritdoc IMSA_Config
     */
    function enableExecutor(
        address validator,
        bytes calldata data
    )
        public
        virtual
        override
        onlyEntryPointOrSelf
    {
        _enableExecutor(validator, data);
    }

    function _enableExecutor(address validator, bytes calldata data) internal {
        SentinelListLib.SentinelList storage _executors = _getModuleMangerStorage()._executors;
        IExecutor(validator).enable(data);
        _executors.push(validator);

        emit EnableExecutor(validator);
    }

    /**
     * @inheritdoc IMSA_Config
     */
    function disableExecutor(
        address validator,
        bytes calldata data
    )
        external
        override
        onlyEntryPointOrSelf
    {
        (address prevValidator, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        IExecutor(validator).disable(disableModuleData);
        SentinelListLib.SentinelList storage _executors = _getModuleMangerStorage()._executors;
        _executors.pop(prevValidator, validator);

        emit DisableExecutor(validator);
    }

    /**
     * @inheritdoc IMSA_Config
     */
    function isExecutorEnabled(address executor) public view virtual returns (bool) {
        SentinelListLib.SentinelList storage _executors = _getModuleMangerStorage()._executors;
        return _executors.contains(executor);
    }

    function isAlreadyInitialized() internal view virtual returns (bool) {
        ModuleManagerStorage storage ims = _getModuleMangerStorage();
        return ims._validators.alreadyInitialized();
    }
}
