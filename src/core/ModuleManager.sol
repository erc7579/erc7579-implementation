// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "sentinellist/SentinelList.sol";
import "./AccountBase.sol";
import "../interfaces/IMSA.sol";
import "../interfaces/IModule.sol";

abstract contract ModuleManager is AccountBase, IMSA_Config {
    using SentinelListLib for SentinelListLib.SentinelList;

    error InvalidModule(address module);

    // linked list of validators. List is initialized by initializeAccount()
    SentinelListLib.SentinelList internal _validators;
    // linked list of executors. List is initialized by initializeAccount()
    SentinelListLib.SentinelList internal _executors;

    modifier onlyExecutorModule() {
        if (!_executors.contains(msg.sender)) revert InvalidModule(msg.sender);
        _;
    }

    modifier onlyValidatorModule(address validator) {
        if (!_validators.contains(validator)) revert InvalidModule(validator);
        _;
    }

    /**
     * @inheritdoc IMSA_Config
     */
    function enableValidator(
        address validator,
        bytes calldata data
    )
        external
        override
        onlyEntryPoint
    {
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
        onlyEntryPoint
    {
        // decode prev validator cause this is a linked list (optional)
        (address prevValidator, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        IValidator(validator).disable(disableModuleData);
        _validators.pop(prevValidator, validator);
        emit DisableValidator(validator);
    }

    /**
     * @inheritdoc IMSA_Config
     */
    function isValidatorEnabled(address validator) external view returns (bool) {
        return _validators.contains(validator);
    }

    /**
     * @inheritdoc IMSA_Config
     */
    function enableExecutor(
        address validator,
        bytes calldata data
    )
        external
        override
        onlyEntryPoint
    {
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
        onlyEntryPoint
    {
        (address prevValidator, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        IExecutor(validator).disable(disableModuleData);
        _executors.pop(prevValidator, validator);

        emit DisableExecutor(validator);
    }

    /**
     * @inheritdoc IMSA_Config
     */
    function isExecutorEnabled(address executor) external view returns (bool) {
        return _executors.contains(executor);
    }
}
