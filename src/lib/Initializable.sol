// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

bytes32 constant INIT_SLOT = keccak256(
    abi.encode(uint256(keccak256("initializable.transient.msa")) - 1)
) & ~bytes32(uint256(0xff));

library Initializable {
    error NotInitializable();

    function checkInitializable() internal view {
        bytes32 slot = INIT_SLOT;
        // Load the current value from the slot, revert if 0
        assembly {
            let isInitializable := tload(slot)
            if iszero(isInitializable) {
                mstore(0x0, 0xaed59595) // NotInitializable()
                revert(0x1c, 0x04)
            }
        }
    }

    function setInitializable() internal {
        bytes32 slot = INIT_SLOT;
        assembly {
            tstore(slot, 0x01)
        }
    }
}
