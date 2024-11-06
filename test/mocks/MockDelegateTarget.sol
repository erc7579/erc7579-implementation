// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockDelegateTarget {
    function sendValue(address target, uint256 _value) public {
        (bool success,) = target.call{ value: _value }("");
        success;
    }
}
