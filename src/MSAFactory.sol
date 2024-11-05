// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IMSA } from "./interfaces/IMSA.sol";
import { MSAProxy } from "./utils/MSAProxy.sol";

contract MSAFactory {
    address public immutable implementation;

    constructor(address _msaImplementation) {
        implementation = _msaImplementation;
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
        address account = address(
            new MSAProxy{ salt: salt, value: msg.value }(
                implementation, abi.encodeCall(IMSA.initializeAccount, initCode)
            )
        );

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
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(
                    abi.encodePacked(
                        type(MSAProxy).creationCode,
                        abi.encode(implementation, abi.encodeCall(IMSA.initializeAccount, initcode))
                    )
                )
            )
        );

        return address(uint160(uint256(hash)));
    }
}
