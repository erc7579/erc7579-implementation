// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "sentinellist/SentinelList.sol";
import "./AccountBase.sol";
import "../interfaces/IMSA.sol";
import "../interfaces/IModule.sol";

abstract contract ModuleManager is AccountBase, IMSA_Management {
    error InvalidModule(address module);

    using SentinelListLib for SentinelListLib.SentinelList;

    SentinelListLib.SentinelList internal _validators;
    SentinelListLib.SentinelList internal _executors;

    modifier onlyExecutorModule() {
        if (!_executors.contains(msg.sender)) revert InvalidModule(msg.sender);
        _;
    }

    modifier onlyValidatorModule(address validator) {
        if (!_validators.contains(validator)) revert InvalidModule(validator);
        _;
    }

    function enableValidator(
        address validator,
        bytes calldata data
    )
        external
        override
        onlyEntryPoint
    {
        _validators.push(validator);
        emit EnableValidator(validator);
    }

    function disableValidator(
        address validator,
        bytes calldata data
    )
        external
        override
        onlyEntryPoint
    {
        // decode prev validator cause this is a linked list (optional)
        address prevValidator = abi.decode(data, (address));
        _validators.pop(prevValidator, validator);
        emit DisableValidator(validator);
    }

    function isValidatorEnabled(address validator) external view returns (bool) {
        return _validators.contains(validator);
    }

    function enableExecutor(
        address validator,
        bytes calldata data
    )
        external
        override
        onlyEntryPoint
    { }

    function disableExecutor(
        address validator,
        bytes calldata data
    )
        external
        override
        onlyEntryPoint
    { }

    function isExecutorEnabled(address executor) external view returns (bool) {
        return _executors.contains(executor);
    }
}
