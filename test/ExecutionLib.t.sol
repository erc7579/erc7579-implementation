// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "src/lib/ExecutionLib.sol";

contract ExecutionLibTest is Test {
    function setUp() public { }

    function test_encode_decode(address target, uint256 value, bytes memory callData) public {
        bytes memory encoded = ExecutionLib.encodeSingle(target, value, callData);
        console2.logBytes(encoded);
        console2.log("calldata");
        console2.logBytes(callData);
        (address _target, uint256 _value, bytes memory _callData) = this.decode(encoded);

        assertTrue(_target == target);
        assertTrue(_value == value);
        assertTrue(keccak256(_callData) == keccak256(callData));
    }

    function decode(bytes calldata encoded)
        public
        pure
        returns (address _target, uint256 _value, bytes calldata _callData)
    {
        (_target, _value, _callData) = ExecutionLib.decodeSingle(encoded);
    }
}
