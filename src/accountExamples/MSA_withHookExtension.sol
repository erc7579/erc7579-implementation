// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { MSA as MSA_ValidatorInNonce, MSABase } from "./MSA_ValidatorInNonce.sol";
import "../core/HookManager.sol";

/**
 * @title reference implementation of the minimal modular smart account with Hook Extension
 * @author zeroknots.eth | rhinestone.wtf
 */
contract MSA is MSA_ValidatorInNonce, HookManager {
    /**
     * @inheritdoc IExecution
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        payable
        virtual
        override
        onlyEntryPointOrSelf
        withHook
        returns (bytes memory result)
    {
        return _execute(target, value, callData);
    }

    /**
     * @inheritdoc IExecution
     */
    function executeBatch(Execution[] calldata executions)
        external
        payable
        override
        onlyEntryPointOrSelf
        withHook
        returns (bytes[] memory result)
    {
        result = _execute(executions);
    }

    /**
     * @inheritdoc IExecution
     */
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
        withHook
        returns (bytes memory returnData)
    {
        returnData = _execute(target, value, callData);
    }

    /**
     * @inheritdoc IExecution
     */
    function executeBatchFromExecutor(Execution[] calldata executions)
        external
        payable
        virtual
        override
        onlyExecutorModule
        withHook
        returns (bytes[] memory returnDatas)
    {
        returnDatas = _execute(executions);
    }

    /////////////////////////////////////////////////////
    // Unsafe Executions - Implement this with care!
    ////////////////////////////////////////////////////
    /**
     * @inheritdoc IExecutionUnsafe
     */
    function executeDelegateCall(
        address target,
        bytes calldata callData
    )
        external
        payable
        virtual
        override
        onlyEntryPointOrSelf
        withHook
        returns (bytes memory result)
    {
        return _executeDelegatecall(target, callData);
    }
    /**
     * @inheritdoc IExecutionUnsafe
     */

    function executeDelegateCallFromExecutor(
        address target,
        bytes memory callData
    )
        external
        payable
        virtual
        override
        onlyExecutorModule
        withHook
        returns (bytes memory)
    {
        revert Unsupported();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(MSABase, HookManager)
        returns (bool)
    {
        return interfaceId == type(IAccountConfig_Hook).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
