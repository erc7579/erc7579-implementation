// SPDX-License-Identifier: MIT
import "./interfaces/IERC4337.sol";
import "./interfaces/IMSA.sol";
import "./core/Execution.sol";
import "./core/Fallback.sol";
import "./core/ModuleManager.sol";

import "forge-std/interfaces/IERC165.sol";

contract MSA is IERC165, Execution, ModuleManager, IERC4337, IMSA_Exec, Fallback {
    using SentinelListLib for SentinelListLib.SentinelList;

    /**
     * Validator selectiion / encoding is NOT in scope of this standard.
     * This is just an example of how it could be done.
     *
     */
    function validateUserOp(
        UserOperation memory userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        payPrefund(missingAccountFunds)
        returns (uint256 validSignature)
    {
        // Special thanks to taek (ZeroDev) for this trick
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

        // MSA MUST clean up signature encoding before sending userOp to IValidator
        userOp.signature = userOpSignature[20:];

        // check if validator is enabled
        if (!_validators.contains(validator)) revert InvalidModule(validator);
        validSignature =
            IValidator(validator).validateUserOp(userOp, userOpHash, missingAccountFunds);
    }

    function isValidSignature(bytes32 hash, bytes calldata data) external view returns (bytes4) {
        address validator = address(bytes20(data[0:20]));
        if (!_validators.contains(validator)) revert InvalidModule(validator);
        return IValidator(validator).isValidSignature(hash, data[20:]);
    }

    /////////////////////////////////////////////////////
    // Executions
    ////////////////////////////////////////////////////

    /**
     * @inheritdoc IMSA_Exec
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        payable
        override
        onlyEntryPoint
        returns (bytes memory result)
    {
        return _execute(target, value, callData);
    }

    /**
     * @inheritdoc IMSA_Exec
     */
    function executeDelegateCall(
        address target,
        bytes calldata callData
    )
        external
        payable
        override
        onlyEntryPoint
        returns (bytes memory result)
    {
        return _executeDelegatecall(target, callData);
    }

    /**
     * @inheritdoc IMSA_Exec
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata callDatas
    )
        external
        payable
        override
        onlyEntryPoint
        returns (bytes[] memory result)
    {
        result = _execute(targets, values, callDatas);
    }

    /**
     * @inheritdoc IMSA_Exec
     */
    function executeFromModule(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        payable
        override
        onlyExecutorModule
        returns (bytes memory returnData)
    {
        returnData = _execute(target, value, callData);
    }

    /**
     * @inheritdoc IMSA_Exec
     */
    function executeBatchFromModule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata callDatas
    )
        external
        payable
        override
        onlyExecutorModule
        returns (bytes[] memory returnDatas)
    {
        returnDatas = _execute(targets, values, callDatas);
    }

    /**
     * @inheritdoc IMSA_Exec
     */
    function executeDelegateCallFromModule(
        address target,
        bytes memory callData
    )
        external
        payable
        override
        onlyExecutorModule
        returns (bytes memory)
    {
        revert Unsupported();
    }

    /////////////////////////////////////////////////////
    // Account Initialization
    ////////////////////////////////////////////////////

    /**
     * @inheritdoc IMSA_Config
     */
    function initializeAccount(bytes calldata data) external override {
        if (_validators.alreadyInitialized()) revert();
        address defaultValidator = abi.decode(data, (address));
        _validators.init();
        _executors.init();
        _validators.push(defaultValidator);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        if (interfaceID == type(IERC165).interfaceId) {
            return true;
        } else if (interfaceID == type(IMSA_Exec).interfaceId) {
            return true;
        } else if (interfaceID == type(IMSA_Config).interfaceId) {
            return true;
        } else if (interfaceID == type(IERC4337).interfaceId) {
            return true;
        } else {
            return false;
        }
    }
}
