// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

string constant INIT_NOTATION = "SignedInit(address bootstrap,bytes bootstrapInit)";
bytes32 constant INIT_TYPEHASH = keccak256(abi.encodePacked(INIT_NOTATION));

library HashLib {
    function hash(address bootstrap, bytes memory bootstrapInit) internal pure returns (bytes32) {
        return keccak256(abi.encode(INIT_TYPEHASH, bootstrap, keccak256(bootstrapInit)));
    }
}
