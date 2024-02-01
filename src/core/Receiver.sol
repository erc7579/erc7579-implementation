// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title Receiver
 * @dev This contract receives safe-transferred ERC721 and ERC1155 tokens.
 * @author Modified from Solady
 * (https://github.com/Vectorized/solady/blob/main/src/accounts/Receiver.sol)
 */
abstract contract Receiver {
    /// @dev For receiving ETH.
    receive() external payable virtual { }

    /// @dev Fallback function with the `receiverFallback` modifier.
    fallback() external payable virtual receiverFallback { }

    /// @dev Modifier for the fallback function to handle token callbacks.
    modifier receiverFallback() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, calldataload(0))
            // 0x150b7a02: `onERC721Received(address,address,uint256,bytes)`.
            // 0xf23a6e61: `onERC1155Received(address,address,uint256,uint256,bytes)`.
            // 0xbc197c81: `onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)`.
            if or(eq(s, 0x150b7a02), or(eq(s, 0xf23a6e61), eq(s, 0xbc197c81))) {
                mstore(0x20, s) // Store `msg.sig`.
                return(0x3c, 0x20) // Return `msg.sig`.
            }
        }
        _;
    }
}
