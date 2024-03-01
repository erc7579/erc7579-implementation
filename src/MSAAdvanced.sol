// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./lib/ModeLib.sol";
import { ExecutionLib } from "./lib/ExecutionLib.sol";
import { ExecutionHelper } from "./core/ExecutionHelper.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import "./interfaces/IERC7579Module.sol";
import { IERC7579Account } from "./interfaces/IERC7579Account.sol";
import { IMSA } from "./interfaces/IMSA.sol";
import { ModuleManager } from "./core/ModuleManager.sol";
import { HookManager } from "./core/HookManager.sol";

/**
 * @author zeroknots.eth | rhinestone.wtf
 * Reference implementation of a very simple ERC7579 Account.
 * This account implements CallType: SINGLE, BATCH and DELEGATECALL.
 * This account implements ExecType: DEFAULT and TRY.
 * Hook support is implemented
 */
contract MSAAdvanced is IMSA, ExecutionHelper, ModuleManager, HookManager {
    using ExecutionLib for bytes;
    using ModeLib for ModeCode;

    /**
     * @inheritdoc IERC7579Account
     * @dev this function is only callable by the entry point or the account itself
     * @dev this function demonstrates how to implement
     * CallType SINGLE and BATCH and ExecType DEFAULT and TRY
     * @dev this function demonstrates how to implement hook support (modifier)
     */
    function execute(
        ModeCode mode,
        bytes calldata executionCalldata
    )
        external
        payable
        onlyEntryPointOrSelf
        withHook
    {
        (CallType callType, ExecType execType,,) = mode.decode();

        // check if calltype is batch or single
        if (callType == CALLTYPE_BATCH) {
            // destructure executionCallData according to batched exec
            Execution[] calldata executions = executionCalldata.decodeBatch();
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) _execute(executions);
            else if (execType == EXECTYPE_TRY) _tryExecute(executions);
            else revert UnsupportedExecType(execType);
        } else if (callType == CALLTYPE_SINGLE) {
            // destructure executionCallData according to single exec
            (address target, uint256 value, bytes calldata callData) =
                executionCalldata.decodeSingle();
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) _execute(target, value, callData);
            // TODO: implement event emission for tryExecute singleCall
            else if (execType == EXECTYPE_TRY) _tryExecute(target, value, callData);
            else revert UnsupportedExecType(execType);
        } else if (callType == CALLTYPE_DELEGATECALL) {
            // destructure executionCallData according to single exec
            address delegate = address(uint160(bytes20(executionCalldata[0:20])));
            bytes calldata callData = executionCalldata[20:];
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) _executeDelegatecall(delegate, callData);
            else if (execType == EXECTYPE_TRY) _tryExecuteDelegatecall(delegate, callData);
            else revert UnsupportedExecType(execType);
        } else {
            revert UnsupportedCallType(callType);
        }
    }

    /**
     * @inheritdoc IERC7579Account
     * @dev this function is only callable by an installed executor module
     * @dev this function demonstrates how to implement
     * CallType SINGLE and BATCH and ExecType DEFAULT and TRY
     * @dev this function demonstrates how to implement hook support (modifier)
     */
    function executeFromExecutor(
        ModeCode mode,
        bytes calldata executionCalldata
    )
        external
        payable
        onlyExecutorModule
        withHook
        returns (
            bytes[] memory returnData // TODO returnData is not used
        )
    {
        (CallType callType, ExecType execType,,) = mode.decode();

        // check if calltype is batch or single
        if (callType == CALLTYPE_BATCH) {
            // destructure executionCallData according to batched exec
            Execution[] calldata executions = executionCalldata.decodeBatch();
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) returnData = _execute(executions);
            else if (execType == EXECTYPE_TRY) returnData = _tryExecute(executions);
            else revert UnsupportedExecType(execType);
        } else if (callType == CALLTYPE_SINGLE) {
            // destructure executionCallData according to single exec
            (address target, uint256 value, bytes calldata callData) =
                executionCalldata.decodeSingle();
            returnData = new bytes[](1);
            bool success;
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) {
                returnData[0] = _execute(target, value, callData);
            }
            // TODO: implement event emission for tryExecute singleCall
            else if (execType == EXECTYPE_TRY) {
                (success, returnData[0]) = _tryExecute(target, value, callData);
                if (!success) emit TryExecuteUnsuccessful(0, returnData[0]);
            } else {
                revert UnsupportedExecType(execType);
            }
        } else if (callType == CALLTYPE_DELEGATECALL) {
            // destructure executionCallData according to single exec
            address delegate = address(uint160(bytes20(executionCalldata[0:20])));
            bytes calldata callData = executionCalldata[20:];
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) _executeDelegatecall(delegate, callData);
            else if (execType == EXECTYPE_TRY) _tryExecuteDelegatecall(delegate, callData);
            else revert UnsupportedExecType(execType);
        } else {
            revert UnsupportedCallType(callType);
        }
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function executeUserOp(PackedUserOperation calldata userOp)
        external
        payable
        onlyEntryPointOrSelf
    {
        bytes calldata callData = userOp.callData[4:];
        (bool success,) = address(this).delegatecall(callData);
        if (!success) revert ExecutionFailed();
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function installModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata initData
    )
        external
        payable
        onlyEntryPointOrSelf
    {
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) _installValidator(module, initData);
        else if (moduleTypeId == MODULE_TYPE_EXECUTOR) _installExecutor(module, initData);
        else if (moduleTypeId == MODULE_TYPE_FALLBACK) _installFallbackHandler(module, initData);
        else if (moduleTypeId == MODULE_TYPE_HOOK) _installHook(module, initData);
        else revert UnsupportedModuleType(moduleTypeId);
        emit ModuleInstalled(moduleTypeId, module);
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function uninstallModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata deInitData
    )
        external
        payable
        onlyEntryPointOrSelf
    {
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            _uninstallValidator(module, deInitData);
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            _uninstallExecutor(module, deInitData);
        } else if (moduleTypeId == MODULE_TYPE_FALLBACK) {
            _uninstallFallbackHandler(module, deInitData);
        } else if (moduleTypeId == MODULE_TYPE_HOOK) {
            _uninstallHook(module, deInitData);
        } else {
            revert UnsupportedModuleType(moduleTypeId);
        }
        emit ModuleUninstalled(moduleTypeId, module);
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        payable
        virtual
        override
        payPrefund(missingAccountFunds)
        returns (uint256 validSignature)
    {
        address validator;
        // @notice validator encoding in nonce is just an example!
        // @notice this is not part of the standard!
        // Account Vendors may choose any other way to implement validator selection
        uint256 nonce = userOp.nonce;
        assembly {
            validator := shr(96, nonce)
        }

        // check if validator is enabled. If not terminate the validation phase.
        if (!_isValidatorInstalled(validator)) return VALIDATION_FAILED;

        // bubble up the return value of the validator module
        validSignature = IValidator(validator).validateUserOp(userOp, userOpHash);
    }

    /**
     * @dev ERC-1271 isValidSignature
     *         This function is intended to be used to validate a smart account signature
     * and may forward the call to a validator module
     *
     * @param hash The hash of the data that is signed
     * @param data The data that is signed
     */
    function isValidSignature(
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        virtual
        override
        returns (bytes4)
    {
        address validator = address(bytes20(data[0:20]));
        if (!_isValidatorInstalled(validator)) revert InvalidModule(validator);
        return IValidator(validator).isValidSignatureWithSender(msg.sender, hash, data[20:]);
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function isModuleInstalled(
        uint256 moduleTypeId,
        address module,
        bytes calldata additionalContext
    )
        external
        view
        override
        returns (bool)
    {
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            return _isValidatorInstalled(module);
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            return _isExecutorInstalled(module);
        } else if (moduleTypeId == MODULE_TYPE_FALLBACK) {
            return _isFallbackHandlerInstalled(abi.decode(additionalContext, (bytes4)), module);
        } else if (moduleTypeId == MODULE_TYPE_HOOK) {
            return _isHookInstalled(module);
        } else {
            return false;
        }
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function accountId() external view virtual override returns (string memory) {
        // vendor.flavour.SemVer
        return "uMSA.advanced/withHook.v0.1";
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function supportsExecutionMode(ModeCode mode)
        external
        view
        virtual
        override
        returns (bool isSupported)
    {
        (CallType callType, ExecType execType,,) = mode.decode();
        if (callType == CALLTYPE_BATCH) isSupported = true;
        else if (callType == CALLTYPE_SINGLE) isSupported = true;
        else if (callType == CALLTYPE_DELEGATECALL) isSupported = true;
        // if callType is not single, batch or delegatecall return false
        else return false;

        if (execType == EXECTYPE_DEFAULT) isSupported = true;
        else if (execType == EXECTYPE_TRY) isSupported = true;
        // if execType is not default or try, return false
        else return false;
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function supportsModule(uint256 modulTypeId) external view virtual override returns (bool) {
        if (modulTypeId == MODULE_TYPE_VALIDATOR) return true;
        else if (modulTypeId == MODULE_TYPE_EXECUTOR) return true;
        else if (modulTypeId == MODULE_TYPE_FALLBACK) return true;
        else if (modulTypeId == MODULE_TYPE_HOOK) return true;
        else return false;
    }

    /**
     * @dev Initializes the account. Function might be called directly, or by a Factory
     * @param data. encoded data that can be used during the initialization phase
     */
    function initializeAccount(bytes calldata data) public payable virtual {
        // checks if already initialized and reverts before setting the state to initialized
        _initModuleManager();

        // this is just implemented for demonstration purposes. You can use any other initialization
        // logic here.
        (address bootstrap, bytes memory bootstrapCall) = abi.decode(data, (address, bytes));
        (bool success,) = bootstrap.delegatecall(bootstrapCall);
        if (!success) revert();
    }
}
