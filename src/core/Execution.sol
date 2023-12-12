// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "src/interfaces/IMSA.sol";

/**
 * @title Execution
 * @dev This contract executes calls in the context of this contract.
 * @author zeroknots.eth | rhinestone.wtf
 * shoutout to solady (vectorized, ross) for this code
 * https://github.com/Vectorized/solady/blob/main/src/accounts/ERC4337.sol
 */
contract Execution {
    function _execute(IMSA_Exec.Execution[] calldata executions)
        internal
        returns (bytes[] memory result)
    {
        uint256 length = executions.length;

        // ensure that provided arrays are the same length

        result = new bytes[](length);
        for (uint256 i; i < length; i++) {
            IMSA_Exec.Execution calldata _exec = executions[i];
            result[i] = _execute(_exec.target, _exec.value, _exec.callData);
        }
    }

    function _execute(
        address target,
        uint256 value,
        bytes calldata callData
    )
        internal
        virtual
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, callData.offset, callData.length)
            if iszero(call(gas(), target, value, result, callData.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @dev Execute a delegatecall with `delegate` on this account.
    function _executeDelegatecall(
        address delegate,
        bytes calldata callData
    )
        internal
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, callData.offset, callData.length)
            // Forwards the `data` to `delegate` via delegatecall.
            if iszero(delegatecall(gas(), delegate, result, callData.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }
}
