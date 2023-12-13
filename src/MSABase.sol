// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./interfaces/IERC4337.sol";
import "forge-std/interfaces/IERC165.sol";
import "./interfaces/IMSA.sol";
import "./core/Execution.sol";
import "./core/Fallback.sol";
import "./core/ModuleManager.sol";

/**
 * @title MSABase
 * @author zeroknots.eth | rhinestone.wtf
 * @dev This contract is the base contract for Minimal Modular Smart Accounts.
 * Validator selection / encoding is NOT in scope of this standard.
 * Refer to the examples in this repo for different approaches.
 *      - ./accountExamples/MSA_ValidatorInSignature.sol (validator address is encoded in signature) - Kernel style
 *      - ./accountExamples/MSA_ValidatorInNonce.sol (validator address is encoded in nonce) - Inspired by ross (z0r0z)
 *
 */
abstract contract MSABase is Execution, ModuleManager, IERC4337, IMSA, Fallback {
    /**
     * ERC-4337 validation function
     */
    function validateUserOp(
        UserOperation memory userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        virtual
        returns (uint256 validSignature);

    /**
     * ERC-1271
     */
    function isValidSignature(
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        virtual
        returns (bytes4);

    /////////////////////////////////////////////////////
    // Executions
    ////////////////////////////////////////////////////

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
        returns (bytes memory result)
    {
        return _execute(target, value, callData);
    }

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
        returns (bytes memory result)
    {
        return _executeDelegatecall(target, callData);
    }

    /**
     * @inheritdoc IExecution
     */
    function executeBatch(Execution[] calldata executions)
        external
        payable
        override
        onlyEntryPointOrSelf
        returns (bytes[] memory result)
    {
        result = _execute(executions);
    }

    /**
     * @inheritdoc IExecution
     */
    function executeFromModule(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        payable
        virtual
        override
        onlyExecutorModule
        returns (bytes memory returnData)
    {
        returnData = _execute(target, value, callData);
    }

    /**
     * @inheritdoc IExecution
     */
    function executeBatchFromModule(Execution[] calldata executions)
        external
        payable
        virtual
        override
        onlyExecutorModule
        returns (bytes[] memory returnDatas)
    {
        returnDatas = _execute(executions);
    }

    /**
     * @inheritdoc IExecutionUnsafe
     */
    function executeDelegateCallFromModule(
        address target,
        bytes memory callData
    )
        external
        payable
        virtual
        override
        onlyExecutorModule
        returns (bytes memory)
    {
        revert Unsupported();
    }

    /////////////////////////////////////////////////////
    // Account Initialization
    ////////////////////////////////////////////////////

    /**
     * @inheritdoc IMSA
     */
    function initializeAccount(bytes calldata data) public virtual override {
        // only allow initialization once
        if (isAlreadyInitialized()) revert();

        // this is just implemented for demonstration purposes. You can use any other initialization logic here.
        (address bootstrap, bytes memory bootstrapCall) = abi.decode(data, (address, bytes));
        (bool success,) = bootstrap.delegatecall(bootstrapCall);
        if (!success) revert();
        // revert if bootstrap didnt initialize the linked list of ModuleManager
        if (!isAlreadyInitialized()) revert();
    }

    function supportsInterface(bytes4 interfaceID) public pure virtual override returns (bool) {
        if (interfaceID == type(IMSA).interfaceId) return true;
        return super.supportsInterface(interfaceID);
    }
}
