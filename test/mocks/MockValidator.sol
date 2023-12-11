pragma solidity ^0.8.23;

import "src/interfaces/IModule.sol";
import "src/interfaces/IMSA.sol";

contract MockValidator is IValidator {
    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

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

        return VALIDATION_SUCCESS;
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
