// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IMSA {
    error Unsupported();

    function execute(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        returns (bytes memory result);
    function executeDelegateCall(
        address target,
        bytes calldata callData
    )
        external
        returns (bytes memory result);
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata callDatas
    )
        external
        returns (bytes[] memory result);
    function executeFromModule(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        returns (bytes memory);
    function executeBatchFromModule(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata callDatas
    )
        external
        returns (bytes[] memory);
    function executeDelegateCallFromModule(
        address target,
        bytes memory callData
    )
        external
        returns (bytes memory);
}

interface IMSA_Management {
    event EnableValidator(address module);
    event DisableValidator(address module);

    event EnableExecutor(address module);
    event DisableExecutor(address module);

    function enableValidator(address validator, bytes calldata data) external;
    function disableValidator(address validator, bytes calldata data) external;
    function isValidatorEnabled(address executor) external view returns (bool);
    function enableExecutor(address validator, bytes calldata data) external;
    function disableExecutor(address validator, bytes calldata data) external;
    function isExecutorEnabled(address executor) external view returns (bool);

    function initializeAccount(bytes calldata data) external;
}

interface IMSA_ManagementExtension is IMSA_Management {
    event EnableHook(address module);
    event DisableHook(address module);

    function enableHook(address hook, bytes calldata data) external;
    function disableHook(address hook, bytes calldata data) external;
    function isHookEnabled(address executor) external view returns (bool);
}
