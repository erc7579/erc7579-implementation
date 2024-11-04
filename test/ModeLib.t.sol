// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "src/lib/ModeLib.sol";

contract ModeLibTest is Test {
    function setUp() public { }

    function test_encode_decode_single() public pure {
        CallType callType = CALLTYPE_SINGLE;
        ExecType execType = EXECTYPE_DEFAULT;
        ModeSelector modeSelector = MODE_DEFAULT;
        ModePayload payload = ModePayload.wrap(bytes22(hex"01"));
        ModeCode enc = ModeLib.encode(callType, execType, modeSelector, payload);

        (CallType _calltype, ExecType _execType, ModeSelector _mode,) = ModeLib.decode(enc);
        assertTrue(_calltype == callType);
        assertTrue(_execType == execType);
        assertTrue(_mode == modeSelector);
        // assertTrue(_payload == payload);
    }

    function test_encode_decode_batch() public pure {
        CallType callType = CALLTYPE_BATCH;
        ExecType execType = EXECTYPE_DEFAULT;
        ModeSelector modeSelector = MODE_DEFAULT;
        ModePayload payload = ModePayload.wrap(bytes22(hex"01"));
        ModeCode enc = ModeLib.encode(callType, execType, modeSelector, payload);

        (CallType _calltype, ExecType _execType, ModeSelector _mode,) = ModeLib.decode(enc);
        assertTrue(_calltype == callType);
        assertTrue(_execType == execType);
        assertTrue(_mode == modeSelector);
        // assertTrue(_payload == payload);
    }
}
