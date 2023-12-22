// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { MSABase } from "../MSABase.sol";
import { IValidator } from "../interfaces/IModule.sol";

contract MSA is MSABase {
    /**
     * Validator selection / encoding is NOT in scope of this standard.
     * This is just an example of how it could be done.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        payable
        virtual
        override
        payPrefund(missingAccountFunds)
        returns (uint256 validSignature)
    {
        address validator;
        uint256 nonce = userOp.nonce;
        assembly {
            validator := shr(96, nonce)
        }

        // check if validator is enabled
        if (!isValidatorInstalled(validator)) revert InvalidModule(validator);
        validSignature = IValidator(validator).validateUserOp(userOp, userOpHash);
    }

    function isValidSignature(
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        virtual
        override
        returns (bytes4)
    {
        return _isValidSignature(hash, data);
    }

    function _isValidSignature(bytes32 hash, bytes calldata data) internal view returns (bytes4) {
        address validator = address(bytes20(data[0:20]));
        if (!isValidatorInstalled(validator)) revert InvalidModule(validator);
        return IValidator(validator).isValidSignatureWithSender(msg.sender, hash, data[20:]);
    }
}
