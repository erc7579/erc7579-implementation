pragma solidity ^0.8.23;

import "src/interfaces/IModule.sol";

contract MockValidator is IValidator {
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
        return VALIDATION_SUCCESS;
    }

    function isValidSignature(
        bytes32 hash,
        bytes calldata data
    )
        external
        override
        returns (bytes4)
    { }
}
