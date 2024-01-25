// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./lib/ModeLib.sol";
import { ExecutionLib } from "./lib/ExecutionLib.sol";
import { ExecutionHelper } from "./core/ExecutionHelper.sol";
import { PackedUserOperation as UserOperation } from
    "account-abstraction/interfaces/PackedUserOperation.sol";
import "./interfaces/IERC7579Account.sol";
import "./interfaces/IERC7579Module.sol";
import { ModuleManager } from "./core/ModuleManager.sol";
import { HookManager } from "./core/HookManager.sol";

contract MSAAdvanced is ExecutionHelper, IERC7579Account, ModuleManager, HookManager {
    using ExecutionLib for bytes;
    using ModeLib for ModeCode;

    /**
     * @inheritdoc IERC7579Account
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
        } else {
            revert UnsupportedCallType(callType);
        }
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function executeFromExecutor(
        ModeCode mode,
        bytes calldata executionCalldata
    )
        external
        payable
        onlyExecutorModule
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
        } else {
            revert UnsupportedCallType(callType);
        }
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function executeUserOp(UserOperation calldata userOp) external payable onlyEntryPointOrSelf {
        bytes calldata callData = userOp.callData[4:];
        (bool success,) = address(this).delegatecall(callData);
        if (!success) revert ExecutionFailed();
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function installModule(
        uint256 moduleType,
        address module,
        bytes calldata initData
    )
        external
        payable
        onlyEntryPointOrSelf
    {
        if (moduleType == MODULE_TYPE_VALIDATOR) _installValidator(module, initData);
        else if (moduleType == MODULE_TYPE_EXECUTOR) _installExecutor(module, initData);
        else if (moduleType == MODULE_TYPE_FALLBACK) _installFallbackHandler(module, initData);
        else if (moduleType == MODULE_TYPE_HOOK) _installHook(module, initData);
        else revert UnsupportedModuleType(moduleType);
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function uninstallModule(
        uint256 moduleType,
        address module,
        bytes calldata deInitData
    )
        external
        payable
        onlyEntryPointOrSelf
    {
        if (moduleType == MODULE_TYPE_VALIDATOR) _uninstallValidator(module, deInitData);
        else if (moduleType == MODULE_TYPE_EXECUTOR) _uninstallExecutor(module, deInitData);
        else if (moduleType == MODULE_TYPE_FALLBACK) _uninstallFallbackHandler(module, deInitData);
        else if (moduleType == MODULE_TYPE_HOOK) _uninstallHook(module, deInitData);
        else revert UnsupportedModuleType(moduleType);
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function validateUserOp(
        UserOperation calldata userOp,
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
        // @notice validator encodig in nonce is just an example!
        // @notice this is not part of the standard!
        // Account Vendors may choose any other way to impolement validator selection
        uint256 nonce = userOp.nonce;
        assembly {
            validator := shr(96, nonce)
        }

        // check if validator is enabled. If terminate the validation phase.
        if (!_isValidatorInstalled(validator)) return VALIDATION_FAILED;

        // bubble up the return value of the validator module
        validSignature = IValidator(validator).validateUserOp(userOp, userOpHash);
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function isModuleInstalled(
        uint256 moduleType,
        address module,
        bytes calldata additionalContext
    )
        external
        view
        override
        returns (bool)
    {
        if (moduleType == MODULE_TYPE_VALIDATOR) return _isValidatorInstalled(module);
        else if (moduleType == MODULE_TYPE_EXECUTOR) return _isExecutorInstalled(module);
        else if (moduleType == MODULE_TYPE_FALLBACK) return _isFallbackHandlerInstalled(module);
        else if (moduleType == MODULE_TYPE_HOOK) return _isHookInstalled(module);
        else return false;
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
    function supportsAccountMode(ModeCode mode)
        external
        view
        virtual
        override
        returns (bool isSupported)
    {
        (CallType callType, ExecType execType,,) = mode.decode();
        if (callType == CALLTYPE_BATCH) isSupported = true;
        else if (callType == CALLTYPE_SINGLE) isSupported = true;
        // if callType is not batch or single, return false
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
     * @inheritdoc IERC7579Account
     */
    function initializeAccount(bytes calldata data) public payable virtual override {
        // only allow initialization once
        if (isAlreadyInitialized()) revert();
        _initModuleManager();

        // this is just implemented for demonstration purposes. You can use any other initialization
        // logic here.
        (address bootstrap, bytes memory bootstrapCall) = abi.decode(data, (address, bytes));
        (bool success,) = bootstrap.delegatecall(bootstrapCall);
        if (!success) revert();
    }
}
