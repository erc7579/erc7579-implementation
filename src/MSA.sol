// SPDX-License-Identifier: MIT
import "./interfaces/IERC4337.sol";
import "./interfaces/IMSA.sol";
import "./core/Execution.sol";
import "./core/ModuleManager.sol";

contract MSA is Execution, ModuleManager, IERC4337, IMSA {
    using SentinelListLib for SentinelListLib.SentinelList;

    function validateUserOp(
        UserOperation memory userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        override
        payPrefund(missingAccountFunds)
        returns (uint256 validSignature)
    {
        bytes calldata userOpSignature;
        uint256 userOpEndOffset;
        assembly {
            userOpEndOffset := add(calldataload(0x04), 0x24)
            userOpSignature.offset :=
                add(calldataload(add(userOpEndOffset, 0x120)), userOpEndOffset)
            userOpSignature.length := calldataload(sub(userOpSignature.offset, 0x20))
        }

        // get validator address from signature
        address validator = address(bytes20(userOpSignature[0:20]));

        // clean up signature
        userOp.signature = userOpSignature[20:];

        // check if validator is enabled
        if (!_validators.contains(validator)) revert InvalidModule(validator);
        validSignature =
            IValidator(validator).validateUserOp(userOp, userOpHash, missingAccountFunds);
    }

    /////////////////////////////////////////////////////
    // Executions
    ////////////////////////////////////////////////////
    function execute(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        override
        onlyEntryPoint
        returns (bytes memory result)
    {
        return _execute(target, value, callData);
    }

    function executeDelegateCall(
        address target,
        bytes calldata callData
    )
        external
        override
        onlyEntryPoint
        returns (bytes memory result)
    {
        return _executeDelegatecall(target, callData);
    }

    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata callDatas
    )
        external
        override
        onlyEntryPoint
        returns (bytes[] memory result)
    {
        result = _execute(targets, values, callDatas);
    }

    function executeFromModule(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        override
        onlyExecutorModule
        returns (bytes memory returnData)
    {
        returnData = _execute(target, value, callData);
    }

    function executeBatchFromModule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata callDatas
    )
        external
        override
        onlyExecutorModule
        returns (bytes[] memory returnDatas)
    {
        returnDatas = _execute(targets, values, callDatas);
    }

    function executeDelegateCallFromModule(
        address target,
        bytes memory callData
    )
        external
        override
        onlyExecutorModule
        returns (bytes memory)
    {
        revert Unsupported();
    }

    /////////////////////////////////////////////////////
    // Account Initialization
    ////////////////////////////////////////////////////

    function initializeAccount(bytes calldata data) external override {
        address defaultValidator = abi.decode(data, (address));
        _validators.init();
        _executors.init();
        _validators.push(defaultValidator);
    }
}
