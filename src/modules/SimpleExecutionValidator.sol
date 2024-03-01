// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../interfaces/IERC7579Account.sol";
import "../interfaces/IERC7579Module.sol";
import "../lib/ModeLib.sol";
import "../lib/ExecutionLib.sol";

contract SimpleExecutionValidator is IValidator {
    using ExecutionLib for bytes;

    error InvalidExec();

    mapping(address => bool) internal _initialized;

    function onInstall(bytes calldata data) external override {
        if (isInitialized(msg.sender)) revert AlreadyInitialized(msg.sender);
        _initialized[msg.sender] = true;
    }

    function onUninstall(bytes calldata data) external override {
        if (!isInitialized(msg.sender)) revert NotInitialized(msg.sender);
        _initialized[msg.sender] = false;
    }

    function isInitialized(address smartAccount) public view override returns (bool) {
        return _initialized[smartAccount];
    }

    function isModuleType(uint256 moduleTypeId) external view override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    )
        external
        override
        returns (uint256)
    {
        // get the function selector that will be called by EntryPoint
        bytes4 execFunction = bytes4(userOp.callData[:4]);

        // get the mode
        CallType callType = CallType.wrap(bytes1(userOp.callData[4]));
        bytes calldata executionCalldata = userOp.callData[36:];
        if (callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = executionCalldata.decodeBatch();
        } else if (callType == CALLTYPE_SINGLE) {
            (address target, uint256 value, bytes calldata callData) =
                executionCalldata.decodeSingle();
        }
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        override
        returns (bytes4)
    { }
}
