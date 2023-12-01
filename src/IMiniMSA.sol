// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IMSA {
    error Unauthorized();
    error Unsupported();

    function execute(address target, uint256 value, bytes calldata callData) external returns (bytes memory result);
    function executeDelegateCall(address target, bytes calldata callData) external returns (bytes memory result);

    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata callDatas) external;
    function executeFromModule(address target, uint256 value, bytes calldata callData)
        external
        returns (bool, bytes memory);
    function executeBatchFromModule(address[] calldata target, uint256[] calldata value, bytes[] calldata callDatas)
        external
        returns (bool, bytes memory);
    function executeDelegateCallFromModule(address target, bytes memory callData)
        external
        returns (bool, bytes memory);
}
