// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { MSA as MSA_ValidatorInNonce } from "./MSA_ValidatorInNonce.sol";

contract MSA is MSA_ValidatorInNonce {
    mapping(bytes32 hash => uint256 signed) _signedMessages;

    event SignedMessage(bytes32 hash);

    function isValidSignature(
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        override
        returns (bytes4 returnValue)
    {
        if (data.length == 0 && _signedMessages[hash] == 1) return this.isValidSignature.selector;
        returnValue = _isValidSignature(hash, data);
    }

    function signMessage(bytes32 hash) external onlyEntryPointOrSelf {
        _signedMessages[hash] = 1;
        emit SignedMessage(hash);
    }
}
