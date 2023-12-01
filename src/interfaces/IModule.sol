// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC4337.sol";

interface IModuleBase {
    function enable(bytes calldata data) external;
    function disable(bytes calldata data) external;
}

interface IValidator is IModuleBase {
    function validateUserOp(
        IERC4337.UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        returns (uint256);

    function isValidSignature(bytes32 hash, bytes calldata data) external returns (bytes4);
}

interface IExecutor is IModuleBase { }

interface IHook is IModuleBase { }
