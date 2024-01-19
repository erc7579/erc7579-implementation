// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title ModeLib
 * |--------------------------------------------------------------------|
 * | CALLTYPE  | EXECTYPE  |   UNUSED   | MODESELECTOR  |  MODE_PAYLOAD |
 * |--------------------------------------------------------------------|
 * | 1 byte    | 1 byte    |   4 bytes  | 4 bytes       |   22 bytes    |
 * |--------------------------------------------------------------------|
 *
 * CALLTYPE: 1 byte
 * CallType is used to determine how the data should be decoded.
 * It can be either single, batch or delegatecall. In the future different calls could be added. i.e. staticcall
 * calltype can be used by a validation module to determine how to decode <bytes data>.
 *
 * EXECTYPE: 1 byte
 * ExecType is used to determine how the account should handle the execution.
 * It can indicate if the execution should revert on failure or continue execution.
 *
 * UNUSED: 4 bytes
 * Unused bytes are reserved for future use.
 *
 * MODESELECTOR: bytes4
 * Exec mode is used to determine how the account should handle the execution.
 * Validator Modules do not have to interpret this value.
 * It can indicate if the execution should revert on failure or continue execution.
 *
 * MODESELECTOR_PAYLOAD: 22 bytes
 * Mode payload is used to pass additional data to the smart account execution, this may be interpreted depending on the mode
 * It can be used to decode additional context data that the smart account may interpret to change the execution behavior.
 *
 * CALLDATA: n bytes
 * single, delegatecall or batch exec encoded as bytes
 */
import {Execution} from "../interfaces/IMSA.sol";

bytes1 constant CALLTYPE_SINGLE = hex"01";
bytes1 constant CALLTYPE_BATCH = hex"02";

bytes1 constant EXECTYPE_REVERT = hex"01";
bytes1 constant EXECTYPE_TRY = hex"02";

type MODESELECTOR is bytes4;

MODESELECTOR constant MODE_EXEC = MODESELECTOR.wrap(0x65786563);
MODESELECTOR constant MODE_TRY_EXEC = MODESELECTOR.wrap(0x74727900);
MODESELECTOR constant MODE_CONTEXT = MODESELECTOR.wrap(0xAAAAAAAA);
MODESELECTOR constant MODE_OFFSET = MODESELECTOR.wrap(0xBBBBBBBB);

function eq(MODESELECTOR a, MODESELECTOR b) pure returns (bool) {
    return MODESELECTOR.unwrap(a) == MODESELECTOR.unwrap(b);
}

using {eq as ==} for MODESELECTOR global;

/**
 * this enum informs how the execution should be handled in the execution phase.
 * it should be out of scope for most validation modules
 */
library ModeLib {
    function decode(bytes32 mode)
        internal
        pure
        returns (bytes1 _calltype, bytes1 _execType, MODESELECTOR _mode, bytes26 _context)
    {
        assembly {
            _calltype := mode
            _execType := shl(8, mode)
            _mode := shl(16, mode)
            _context := shl(48, mode)
        }
    }

    function encode(bytes1 calltype, bytes1 execType, MODESELECTOR mode, bytes26 context)
        internal
        pure
        returns (bytes32 _mode)
    {
        return bytes32(abi.encodePacked(calltype, execType, MODESELECTOR.unwrap(mode), context));
    }

    function encodeSimpleBatch(Execution[] calldata executions)
        internal
        pure
        returns (bytes32 mode, bytes memory data)
    {
        mode = encode(CALLTYPE_BATCH, bytes1(0), MODESELECTOR.wrap(bytes4(0)), bytes26(0));
        data = abi.encode(executions);
    }

    function encodeSimpleSingle(address target, uint256 value, bytes calldata callData)
        internal
        pure
        returns (bytes32 mode, bytes memory data)
    {
        mode = encode(CALLTYPE_SINGLE, bytes1(0), MODESELECTOR.wrap(bytes4(0)), bytes26(0));
        data = abi.encode(target, value, callData);
    }

    function getCallType(bytes32 mode) internal pure returns (bytes1) {
        (bytes1 callType,,,) = decode(mode);
        return callType;
    }
}
