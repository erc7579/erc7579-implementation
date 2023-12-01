// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title Execution
 * @dev This contract executes calls in the context of this contract.
 * big shoutout to vectorized / solady for this code
 */
contract Execution {
    function _execute(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata callData
    )
        internal
        returns (bytes[] memory result)
    {
        uint256 length = target.length;

        // ensure that provided arrays are the same length
        if (length != value.length || length != callData.length) revert();

        result = new bytes[](length);
        for (uint256 i; i < length; i++) {
            result[i] = _execute(target[i], value[i], callData[i]);
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
