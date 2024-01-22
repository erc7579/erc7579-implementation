// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "src/lib/ModeLib.sol";

contract ModeLibTest is Test {
    function setUp() public {}

    function test_encode_decode() public {
        bytes1 callType = CALLTYPE_SINGLE;
        bytes1 execType = EXECTYPE_REVERT;
        MODESELECTOR modeSelector = MODE_EXEC;
        bytes32 enc = ModeLib.encode(callType, execType, modeSelector, bytes22(hex"01"));

        console2.logBytes32(enc);

        (bytes1 _calltype, bytes1 _execType, MODESELECTOR _mode, bytes22 _context) = ModeLib.decode(enc);
        assertEq(_calltype, callType);
        assertEq(_execType, execType);
        assertTrue(_mode == modeSelector);
        assertEq(_context, bytes22(hex"01"));
    }
}
