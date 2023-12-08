pragma solidity ^0.8.23;

import "src/interfaces/IModule.sol";
import "src/interfaces/IMSA.sol";

import "forge-std/interfaces/IERC20.sol";

contract ERC20SessionKey is IValidator {
    function enable(bytes calldata data) external override { }

    function disable(bytes calldata data) external override { }

    function validateUserOp(
        IERC4337.UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        override
        returns (uint256)
    {
        bytes4 execSelector = bytes4(userOp.callData[:4]);
        address target = address(bytes20(userOp.callData[16:36]));
        bytes calldata targetCallData = userOp.callData[36:];

        if (execSelector != IMSA_Exec.execute.selector) revert InvalidExecution(execSelector);

        if (target == userOp.sender) revert InvalidTargetAddress(target);

        bytes4 targetSelector = bytes4(targetCallData[:4]);
        if (targetSelector != IERC20.transfer.selector) revert InvalidTargetCall();
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
