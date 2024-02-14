// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

type PackedFallback is bytes32;

library FallbackLib {
    enum CallType {
        STATIC,
        CALL,
        DELEGATECALL
    }

    function pack(address handler, CallType callType) internal pure returns (PackedFallback) {
        return PackedFallback.wrap(bytes32(uint256(uint160(handler)) | (uint256(callType) << 160)));
    }

    function unpack(PackedFallback packed)
        internal
        pure
        returns (address handler, CallType callType)
    {
        handler = address(uint160(uint256(PackedFallback.unwrap(packed))));
        callType = CallType(uint256(PackedFallback.unwrap(packed)) >> 160);
    }
}
