// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IERC7579Account } from "./interfaces/IERC7579Account.sol";
import { LibClone } from "solady/src/utils/LibClone.sol";

contract MSAFactory {
    address public immutable IMPLEMENTATION;

    constructor(address _msaImplementation) {
        IMPLEMENTATION = _msaImplementation;
    }

    function createAccount(
        bytes32 salt,
        bytes calldata initCode
    )
        public
        payable
        virtual
        returns (address)
    {
        bytes32 _salt = _getSalt(salt, initCode);
        (bool alreadyDeployed, address account) =
            LibClone.createDeterministicERC1967(msg.value, IMPLEMENTATION, _salt);

        if (!alreadyDeployed) {
            IERC7579Account(account).initializeAccount(initCode);
        }
        return account;
    }

    function getAddress(
        bytes32 salt,
        bytes calldata initcode
    )
        public
        view
        virtual
        returns (address)
    {
        bytes32 _salt = _getSalt(salt, initcode);
        return LibClone.predictDeterministicAddressERC1967(IMPLEMENTATION, _salt, address(this));
    }

    function _getSalt(
        bytes32 _salt,
        bytes calldata initCode
    )
        public
        pure
        virtual
        returns (bytes32 salt)
    {
        salt = keccak256(abi.encodePacked(_salt, initCode));
    }
}
