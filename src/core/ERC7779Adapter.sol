// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IERC7779 } from "../interfaces/IERC7779.sol";

abstract contract ERC7779Adapter is IERC7779 {
    error NonAuthorizedOnRedelegationCaller();

    // keccak256(abi.encode(uint256(keccak256(bytes("InteroperableDelegatedAccount.ERC.Storage"))) -
    // 1)) & ~bytes32(uint256(0xff));
    bytes32 internal constant ERC7779_STORAGE_BASE =
        0xc473de86d0138e06e4d4918a106463a7cc005258d2e21915272bcb4594c18900;

    struct ERC7779Storage {
        bytes32[] storageBases;
    }
    /*
    * @dev    Externally shares the storage bases that has been used throughout the account.
    *         Majority of 7702 accounts will have their distinctive storage base to reduce the
    chance of storage collision.
    *         This allows the external entities to know what the storage base is of the account.
    *         Wallets willing to redelegate already-delegated accounts should call
    accountStorageBase() to check if it confirms with the account it plans to redelegate.
    *
    *         The bytes32 array should be stored at the storage slot:
    keccak(keccak('InteroperableDelegatedAccount.ERC.Storage')-1) & ~0xff
    *         This is an append-only array so newly redelegated accounts should not overwrite the
    storage at this slot, but just append their base to the array.
    *         This append operation should be done during the initialization of the account.
    */

    function accountStorageBases() external view returns (bytes32[] memory) {
        ERC7779Storage storage $;
        assembly {
            $.slot := ERC7779_STORAGE_BASE
        }
        return $.storageBases;
    }

    function _addStorageBase(bytes32 storageBase) internal {
        ERC7779Storage storage $;
        assembly {
            $.slot := ERC7779_STORAGE_BASE
        }
        $.storageBases.push(storageBase);
    }

    /*
    * @dev    Function called before redelegation.
    *         This function should prepare the account for a delegation to a different
    implementation.
    *         This function could be triggered by the new wallet that wants to redelegate an already
    delegated EOA.
    *         It should uninitialize storages if needed and execute wallet-specific logic to prepare
    for redelegation.
    *         msg.sender should be the owner of the account.
    */
    function onRedelegation() external returns (bool) {
        require(msg.sender == address(this), NonAuthorizedOnRedelegationCaller());
        _onRedelegation();
        return true;
    }

    /// @dev This function is called before redelegation.
    /// @dev Account should override this function to implement the specific logic.
    function _onRedelegation() internal virtual;
}
