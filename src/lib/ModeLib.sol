// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title ModeLib
 * |--------------------------------------------------------------------|
 * | CALLTYPE  | EXECTYPE  |   UNUSED   | ModeSelector  |  ModePayload  |
 * |--------------------------------------------------------------------|
 * | 1 byte    | 1 byte    |   4 bytes  | 4 bytes       |   22 bytes    |
 * |--------------------------------------------------------------------|
 *
 * CALLTYPE: 1 byte
 * CallType is used to determine how the data should be decoded.
 * It can be either single, batch or delegatecall. In the future different calls could be added. i.e.
 * staticcall
 * calltype can be used by a validation module to determine how to decode <bytes data>.
 *
 * EXECTYPE: 1 byte
 * ExecType is used to determine how the account should handle the execution.
 * It can indicate if the execution should revert on failure or continue execution.
 *
 * UNUSED: 4 bytes
 * Unused bytes are reserved for future use.
 *
 * ModeSelector: bytes4
 * Exec mode is used to determine how the account should handle the execution.
 * Validator Modules do not have to interpret this value.
 * It can indicate if the execution should revert on failure or continue execution.
 *
 * ModePayload: 22 bytes
 * Mode payload is used to pass additional data to the smart account execution, this may be
 * interpreted depending on the mode
 * It can be used to decode additional context data that the smart account may interpret to change
 * the execution behavior.
 *
 * CALLDATA: n bytes
 * single, delegatecall or batch exec encoded as bytes
 */
import { Execution } from "../interfaces/IMSA.sol";

type ModeCode is bytes32;

type CallType is bytes1;

type ExecType is bytes1;

type ModeSelector is bytes4;

using { eqModeSelector as == } for ModeSelector global;
using { eqCallType as == } for CallType global;
using { eqExecType as == } for ExecType global;

type ModePayload is bytes22;

CallType constant CALLTYPE_SINGLE = CallType.wrap(0x01);
CallType constant CALLTYPE_BATCH = CallType.wrap(0x02);
// @dev Implementing delegatecall is OPTIONAL!
// implement delegatecall with extreme care.
CallType constant CALLTYPE_DELEGATECALL = CallType.wrap(0xFF);

// @dev default behavior is to revert on failure
// To allow very simple accounts to use mode encoding, the default behavior is to revert on failure
// Since this is value 0x00, no additional encoding is required for simple accounts
ExecType constant EXECTYPE_REVERT = ExecType.wrap(0x00);
// @dev account may elect to change execution behavior. For example "try exec" / "allow fail"
ExecType constant EXECTYPE_TRY = ExecType.wrap(0x01);

ModeSelector constant MODE_DEFAULT = ModeSelector.wrap(bytes4(0x00000000));
ModeSelector constant MODE_OFFSET = ModeSelector.wrap(bytes4(keccak256("default.mode.offset")));

/**
 * @dev ModeLib is a library for encoding and decoding ModeCode
 */
library ModeLib {
    function decode(ModeCode mode)
        internal
        pure
        returns (
            CallType _calltype,
            ExecType _execType,
            ModeSelector _modeSelector,
            ModePayload _modePayload
        )
    {
        assembly {
            _calltype := mode
            _execType := shl(8, mode)
            _modeSelector := shl(48, mode)
            _modePayload := shl(80, mode)
        }
    }

    function encode(
        CallType calltype,
        ExecType execType,
        ModeSelector mode,
        ModePayload context
    )
        internal
        pure
        returns (ModeCode _mode)
    {
        return ModeCode.wrap(
            bytes32(
                abi.encodePacked(calltype, execType, bytes4(0), ModeSelector.unwrap(mode), context)
            )
        );
    }

    function encodeSimpleBatch(Execution[] calldata executions)
        internal
        pure
        returns (ModeCode mode, bytes memory data)
    {
        mode = encode(CALLTYPE_BATCH, EXECTYPE_REVERT, MODE_DEFAULT, ModePayload.wrap(0x00));
        data = abi.encode(executions);
    }

    function encodeSimpleSingle(
        address target,
        uint256 value,
        bytes calldata callData
    )
        internal
        pure
        returns (ModeCode mode, bytes memory data)
    {
        mode = encode(CALLTYPE_SINGLE, EXECTYPE_REVERT, MODE_DEFAULT, ModePayload.wrap(0x00));
        data = abi.encode(target, value, callData);
    }

    function getCallType(ModeCode mode) internal pure returns (CallType calltype) {
        assembly {
            calltype := shr(mode, 248)
        }
    }
}

function eqCallType(CallType a, CallType b) pure returns (bool) {
    return CallType.unwrap(a) == CallType.unwrap(b);
}

function eqExecType(ExecType a, ExecType b) pure returns (bool) {
    return ExecType.unwrap(a) == ExecType.unwrap(b);
}

function eqModeSelector(ModeSelector a, ModeSelector b) pure returns (bool) {
    return ModeSelector.unwrap(a) == ModeSelector.unwrap(b);
}
