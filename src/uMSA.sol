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

    function executeUserOp(UserOperation calldata userOp) external payable onlyEntryPointOrSelf {
        // skip function sig of executeUserOp
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
        // else if (moduleType == MODULE_TYPE_FALLBACK) _installFallback(module, initData);
        // else if (moduleType == MODULE_TYPE_HOOK) _installHook(module, initData);
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
    function initializeAccount(bytes calldata data) external payable {
    }
}
