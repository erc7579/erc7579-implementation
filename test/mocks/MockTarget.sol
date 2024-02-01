// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockTarget {
    uint256 public value;

    function setValue(uint256 _value) public returns (uint256) {
        value = _value;
        return _value;
    }
}
