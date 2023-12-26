// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./AccountBase.sol";
import { IAccountConfig } from "../interfaces/IMSA.sol";
import { IFallback } from "../interfaces/IModule.sol";

/**
 * Fallback Manager inpired by Safe
 * https://github.com/safe-global/safe-contracts/blob/main/contracts/base/FallbackManager.sol
 */
abstract contract Fallback is AccountBase, IAccountConfig {
    error InvalidAddress(address addr);

    event FallbackHandlerChanged(address handler);

    // keccak256("fallbackmanager.storage.msa");
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT =
        0x9c63439e8db454cdf22fd3d05d35ed5ea662f6ebbc519905ab830d38464df094;

    function installFallback(
        address fallbackHandler,
        bytes calldata data
    )
        public
        virtual
        onlyEntryPointOrSelf
    {
        IFallback(fallbackHandler).onInstall(data);
        _setFallback(fallbackHandler);
        emit FallbackHandlerChanged(fallbackHandler);
    }

    function uninstallFallback(
        address fallbackHandler,
        bytes calldata data
    )
        public
        virtual
        onlyEntryPointOrSelf
    {
        IFallback(fallbackHandler).onUninstall(data);
        _setFallback(address(0));
    }

    function isFallbackInstalled(address fallbackHandler) public view returns (bool enabled) {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;

        address _handler;
        assembly {
            _handler := sload(slot)
        }

        enabled = _handler == fallbackHandler;
    }

    /**
     *  @notice Internal function to set the fallback handler.
     *  @param handler contract to handle fallback calls.
     */
    function _setFallback(address handler) internal {
        /*
            If a fallback handler is set to self, then the following attack vector is opened:
            Imagine we have a function like this:
            function withdraw() internal authorized {
                withdrawalAddress.call.value(address(this).balance)("");
            }

            If the fallback method is triggered, the fallback handler appends the msg.sender address to the calldata and calls the fallback handler.
            A potential attacker could call a Safe with the 3 bytes signature of a withdraw function. Since 3 bytes do not create a valid signature,
            the call would end in a fallback handler. Since it appends the msg.sender address to the calldata, the attacker could craft an address 
            where the first 3 bytes of the previous calldata + the first byte of the address make up a valid function signature. The subsequent call would result in unsanctioned access to Safe's internal protected methods.
            For some reason, solidity matches the first 4 bytes of the calldata to a function signature, regardless if more data follow these 4 bytes.
        */
        if (handler == address(this)) revert InvalidAddress(handler);

        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            sstore(slot, handler)
        }
        /* solhint-enable no-inline-assembly */
    }
    // @notice Forwards all calls to the fallback handler if set. Returns 0 if no handler is set.
    // @dev Appends the non-padded caller address to the calldata to be optionally used in the handler
    //      The handler can make use of `HandlerContext.sol` to extract the address.
    //      This is done because in the next call frame the `msg.sender` will be FallbackManager's address
    //      and having the original caller address may enable additional verification scenarios.
    // solhint-disable-next-line payable-fallback,no-complex-fallback

    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            // When compiled with the optimizer, the compiler relies on a certain assumptions on how the
            // memory is used, therefore we need to guarantee memory safety (keeping the free memory point 0x40 slot intact,
            // not going beyond the scratch space, etc)
            // Solidity docs: https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            let handler := sload(slot)
            if iszero(handler) { return(0, 0) }

            let calldataPtr := allocate(calldatasize())
            calldatacopy(calldataPtr, 0, calldatasize())

            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            let senderPtr := allocate(20)
            mstore(senderPtr, shl(96, caller()))

            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, calldataPtr, add(calldatasize(), 20), 0, 0)

            let returnDataPtr := allocate(returndatasize())
            returndatacopy(returnDataPtr, 0, returndatasize())
            if iszero(success) { revert(returnDataPtr, returndatasize()) }
            return(returnDataPtr, returndatasize())
        }
        /* solhint-enable no-inline-assembly */
    }
}
