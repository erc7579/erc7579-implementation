// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC4337.sol";

uint256 constant VALIDATION_SUCCESS = 0;
uint256 constant VALIDATION_FAILED = 1;

interface IModuleBase {
    /**
     * Enable module
     *  This function is called by the MSA during "enableValidator, enableExecutor, enableHook"
     */
    function enable(bytes calldata data) external;

    /**
     * Disable module
     *  This function is called by the MSA during "disableValidator, disableExecutor, disableHook"
     */
    function disable(bytes calldata data) external;
}

interface IValidator is IModuleBase {
    error InvalidExecution(bytes4 functionSig);
    error InvalidTargetAddress(address target);
    error InvalidTargetCall();

    /**
     * @dev Validates a transaction on behalf of the account.
     *         This function is intended to be called by the MSA during the ERC-4337 validaton phase
     * @param userOp The user operation to be validated. The userOp MUST NOT contain any metadata. The MSA MUST clean up the userOp before sending it to the validator.
     * @param userOpHash The hash of the user operation to be validated
     * @param missingAccountFunds. See ERC-4337
     * @return return value according to ERC-4337
     */
    function validateUserOp(
        IERC4337.UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        returns (uint256);

    /**
     * Validator can be used for ERC-1271 validation
     */
    function isValidSignature(bytes32 hash, bytes calldata data) external returns (bytes4);
}

interface IExecutor is IModuleBase {
// function supportsDelegateCall() external view returns (bool);
// function supportsBatchedCall() external view returns (bool);
}

interface IHook is IModuleBase {
    function preCheck(
        address sender,
        address target,
        uint256 value,
        bytes calldata data
    )
        external
        returns (bytes memory hookData);
    function postCheck(bytes calldata hookData) external returns (bool success);
}
