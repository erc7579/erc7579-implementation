// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../MSABase.sol";

contract MSA is MSABase {
    /**
     * Validator selection / encoding is NOT in scope of this standard.
     * This is just an example of how it could be done.
     */
    function validateUserOp(
        UserOperation memory userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        virtual
        override
        payPrefund(missingAccountFunds)
        returns (uint256 validSignature)
    {
        address validator;
        /// @solidity memory-safe-assembly
        assembly {
            calldatacopy(0x00, 0x00, calldatasize())
            validator := shr(96, sload(shl(64, /*key*/ shr(64, /*nonce*/ calldataload(0x84)))))
        }

        // check if validator is enabled
        if (!isValidatorEnabled(validator)) revert InvalidModule(validator);
        validSignature =
            IValidator(validator).validateUserOp(userOp, userOpHash, missingAccountFunds);
    }

    function isValidSignature(
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        override
        returns (bytes4)
    {
        address validator = address(bytes20(data[0:20]));
        if (!isValidatorEnabled(validator)) revert InvalidModule(validator);
        return IValidator(validator).isValidSignatureWithSender(msg.sender, hash, data[20:]);
    }
}
