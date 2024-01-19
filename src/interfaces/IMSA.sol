// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC4337} from "./IERC4337.sol";

struct Execution {
    address target;
    uint256 value;
    bytes callData;
}
/**
 * @dev Execution Interface of the minimal Modular Smart Account standard
 */

interface IMSA is IERC4337 {
    error Unsupported();

    function execute(bytes32 encodedMode, bytes calldata executionCalldata) external payable;
    function executeUserOp(UserOperation calldata userOp) external payable;
    function initializeAccount(bytes calldata data) external payable;
    function installModule(uint256 moduleType, address module, bytes calldata initData) external payable;
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        payable
        returns (uint256 validSignature);
}
