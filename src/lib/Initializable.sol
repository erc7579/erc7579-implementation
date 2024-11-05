bytes32 constant INIT_SLOT = keccak256("msa.initilizable");

library Initializable {
    error NotInitializable();

    function checkInitializable() internal {
        bytes32 slot = INIT_SLOT;
        bool isInitializable;
        assembly {
            isInitializable := tload(slot)
        }

        if (!isInitializable) {
            revert NotInitializable();
        }
    }

    function setInitializable() internal {
        bytes32 slot = INIT_SLOT;
        assembly {
            tstore(slot, 1)
        }
    }
}
