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
        // Special thanks to taek (ZeroDev) for this trick
        bytes calldata moduleSignature;
        uint256 userOpEndOffset;
        address validator;
        assembly {
            userOpEndOffset := add(calldataload(0x04), 0x24)
            moduleSignature.offset :=
                add(add(calldataload(add(userOpEndOffset, 0x120)), userOpEndOffset), 0x14)
            moduleSignature.length := sub(calldataload(sub(moduleSignature.offset, 0x34)), 0x14)
            validator := calldataload(sub(moduleSignature.offset, 0x20))
        }

        userOp.signature = moduleSignature;

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
