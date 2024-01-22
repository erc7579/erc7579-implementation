// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./lib/ModeLib.sol";
import {DecodeLib} from "./lib/DecodeLib.sol";
import {Executor} from "./core/Executor.sol";
import "./interfaces/IERC4337.sol";
import "./interfaces/IModule.sol";
import "./interfaces/IMSA.sol";
import {ModuleManager} from "./core/ModuleManager.sol";

contract uMSA is Executor, IMSA, ModuleManager {
    using DecodeLib for bytes;

    error UnsupportedModuleType(uint256 moduleType);

    function execute(bytes32 encodedMode, bytes calldata executionCalldata) external payable onlyEntryPointOrSelf {
        bytes1 callType = bytes1(encodedMode >> 248);

        if (callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = executionCalldata.decodeBatch();
            _execute(executions);
        } else if (callType == CALLTYPE_SINGLE) {
            (address target, uint256 value, bytes calldata callData) = executionCalldata.decodeSingle();
            _execute(target, value, callData);
        }
    }

    function executeFromExecutor(bytes32 encodedMode, bytes calldata executionCalldata)
        external
        payable
        onlyExecutorModule
    {
        bytes1 callType = bytes1(encodedMode >> 248);

        if (callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = executionCalldata.decodeBatch();
            _execute(executions);
        } else if (callType == CALLTYPE_SINGLE) {
            (address target, uint256 value, bytes calldata callData) = executionCalldata.decodeSingle();
            _execute(target, value, callData);
        }
    }

    function executeUserOp(UserOperation calldata userOp) external payable onlyEntryPointOrSelf {
        // TODO: how should we implement this?
        // @dev: while this is minimalistic, I think this will break Hooks. caue msgSender used in hooks will now be address(this)
        bytes calldata callData = userOp.callData[4:];
        (bool success,) = address(this).call(callData);
        require(success, "executeUserOp failed");
    }

    function installModule(uint256 moduleType, address module, bytes calldata initData)
        external
        payable
        onlyEntryPointOrSelf
    {
        if (moduleType == MODULE_TYPE_VALIDATOR) _installValidator(module, initData);
        else if (moduleType == MODULE_TYPE_EXECUTOR) _installExecutor(module, initData);
        // TODO: implement fallback and hook
        // else if (moduleType == MODULE_TYPE_FALLBACK) _installFallback(module, initData);
        // else if (moduleType == MODULE_TYPE_HOOK) _installHook(module, initData);
        else revert UnsupportedModuleType(moduleType);
    }

    function uninstallModule(uint256 moduleType, address module, bytes calldata deInitData)
        external
        payable
        onlyEntryPointOrSelf
    {
        // TODO: check if this is the last validator
        if (moduleType == MODULE_TYPE_VALIDATOR) _uninstallValidator(module, deInitData);
        else if (moduleType == MODULE_TYPE_EXECUTOR) _uninstallExecutor(module, deInitData);
        // TODO: implement fallback and hook
        // else if (moduleType == MODULE_TYPE_FALLBACK) _uninstallFallback(module, deInitData);
        // else if (moduleType == MODULE_TYPE_HOOK) _uninstallHook(module, deInitData);
        else revert UnsupportedModuleType(moduleType);
    }

    /**
     * Validator selection / encoding is NOT in scope of this standard.
     * This is just an example of how it could be done.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        payable
        virtual
        override
        payPrefund(missingAccountFunds)
        returns (uint256 validSignature)
    {
        address validator;
        uint256 nonce = userOp.nonce;
        assembly {
            validator := shr(96, nonce)
        }

        // check if validator is enabled
        if (!isValidatorInstalled(validator)) return 0;
        validSignature = IValidator(validator).validateUserOp(userOp, userOpHash);
    }

    function initializeAccount(bytes calldata data) public payable virtual override {
        // only allow initialization once
        if (isAlreadyInitialized()) revert();
        _initModuleManager();

        // this is just implemented for demonstration purposes. You can use any other initialization logic here.
        (address bootstrap, bytes memory bootstrapCall) = abi.decode(data, (address, bytes));
        (bool success,) = bootstrap.delegatecall(bootstrapCall);
        if (!success) revert();
    }

    function isModuleModuleInstalled(uint256 moduleType, address module, bytes calldata additionalContext)
        external
        view
        override
        returns (bool)
    {
        if (moduleType == MODULE_TYPE_VALIDATOR) return isValidatorInstalled(module);
        else if (moduleType == MODULE_TYPE_EXECUTOR) return isExecutorInstalled(module);
        else revert UnsupportedModuleType(moduleType);
    }

    function accountId() external view virtual override returns (string memory) {
        return "uMSA.demo.v0.1";
    }

    function executeDelegateCall(address, bytes calldata) external payable {
        revert Unsupported();
    }
}
