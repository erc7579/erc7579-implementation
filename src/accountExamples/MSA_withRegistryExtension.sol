// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { MSA as MSA_ValidatorInNonce, MSABase } from "./MSA_ValidatorInNonce.sol";
import "../core/RegistryAdapter.sol";
import { ModuleManager } from "../core/ModuleManager.sol";
import { IAccountConfig } from "../interfaces/IMSA.sol";
import { Fallback } from "../core/Fallback.sol";

/**
 * @title reference implementation of the minimal modular smart account with registry extension
 * @author @kopy-kat | rhinestone.wtf
 */
contract MSA is MSA_ValidatorInNonce, RegistryAdapter {
    // EXECUTE FUNCTIONS
    function executeFromExecutor(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        payable
        virtual
        override
        onlyExecutorModule
        onlySecureModule(msg.sender)
        returns (bytes memory returnData)
    {
        returnData = _execute(target, value, callData);
    }

    function executeBatchFromExecutor(Execution[] calldata executions)
        external
        payable
        virtual
        override
        onlyExecutorModule
        onlySecureModule(msg.sender)
        returns (bytes[] memory returnDatas)
    {
        returnDatas = _execute(executions);
    }

    /////////////////////////////////////////////////////
    // Unsafe Executions - Implement this with care!
    ////////////////////////////////////////////////////
    function executeDelegateCallFromExecutor(
        address target,
        bytes memory callData
    )
        external
        payable
        virtual
        override
        onlyExecutorModule
        onlySecureModule(msg.sender)
        returns (bytes memory)
    {
        revert Unsupported();
    }

    // ACCOUNT CONFIG FUNCTIONS
    function installValidator(
        address validator,
        bytes calldata data
    )
        public
        virtual
        override(ModuleManager, IAccountConfig)
        onlyEntryPointOrSelf
        onlySecureModule(validator)
    {
        _installValidator(validator, data);
    }

    function installExecutor(
        address executor,
        bytes calldata data
    )
        public
        virtual
        override(ModuleManager, IAccountConfig)
        onlyEntryPointOrSelf
        onlySecureModule(executor)
    {
        _installExecutor(executor, data);
    }

    function installFallback(
        address fallbackHandler,
        bytes memory data
    )
        public
        virtual
        override(Fallback, IAccountConfig)
        onlyEntryPointOrSelf
        onlySecureModule(fallbackHandler)
    {
        super.installFallback(fallbackHandler, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(MSABase)
        returns (bool)
    {
        // Todo
        // return interfaceId == type(IAccountConfig_Hook).interfaceId
        //     || super.supportsInterface(interfaceId);
    }
}
