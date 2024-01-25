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

/**
 * @author zeroknots.eth | rhinestone.wtf
 * Reference implementation of a very simple ERC7579 Account.
 * This account only implements CallType: SINGLE and BATCH.
 * only the default ExecType is implemented.
 * Hook support is not implemented
 */
contract MSABase is ExecutionHelper, IERC7579Account, ModuleManager {
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
    {
        CallType callType = mode.getCallType();

        if (callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = executionCalldata.decodeBatch();
            _execute(executions);
        } else if (callType == CALLTYPE_SINGLE) {
            (address target, uint256 value, bytes calldata callData) =
                executionCalldata.decodeSingle();
            _execute(target, value, callData);
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
    {
        CallType callType = mode.getCallType();

        if (callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = executionCalldata.decodeBatch();
            _execute(executions);
        } else if (callType == CALLTYPE_SINGLE) {
            (address target, uint256 value, bytes calldata callData) =
                executionCalldata.decodeSingle();
            _execute(target, value, callData);
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
        else revert UnsupportedModuleType(moduleType);
    }

    /**
     * Validator selection / encoding is NOT in scope of this standard.
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
    function initializeAccount(bytes calldata data) public payable virtual override {
        // checks if already initialized and reverts before setting the state to initialized
        _initModuleManager();

        // this is just implemented for demonstration purposes. You can use any other initialization
        // logic here.
        (address bootstrap, bytes memory bootstrapCall) = abi.decode(data, (address, bytes));
        (bool success,) = bootstrap.delegatecall(bootstrapCall);
        if (!success) revert AccountInitializationFailed();
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
        else revert UnsupportedModuleType(moduleType);
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function accountId() external view virtual override returns (string memory) {
        // vendor.flavour.semver
        return "uMSA.simple/noHook.v0.1";
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function supportsAccountMode(ModeCode mode) external view virtual override returns (bool) {
        CallType callType = mode.getCallType();
        if (callType == CALLTYPE_BATCH) return true;
        else if (callType == CALLTYPE_SINGLE) return true;
        else return false;
    }

    /**
     * @inheritdoc IERC7579Account
     */
    function supportsModule(uint256 modulTypeId) external view virtual override returns (bool) {
        if (modulTypeId == MODULE_TYPE_VALIDATOR) return true;
        else if (modulTypeId == MODULE_TYPE_EXECUTOR) return true;
        else if (modulTypeId == MODULE_TYPE_FALLBACK) return true;
        else return false;
    }
}
