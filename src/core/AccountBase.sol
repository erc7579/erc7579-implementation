// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @dev 4337 AccountBase for access control and payPrefund
 * Code is based on Solady's 4337
 */
contract AccountBase {
    error Unauthorized();
    /////////////////////////////////////////////////////
    // Access Control
    ////////////////////////////////////////////////////

    modifier onlyEntryPointOrSelf() virtual {
        if (!(msg.sender == entryPoint() || msg.sender == address(this))) {
            revert Unauthorized();
        }
        _;
    }

    function entryPoint() public view virtual returns (address) {
        return 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    }

    /// @dev Sends to the EntryPoint (i.e. `msg.sender`) the missing funds for this transaction.
    /// Subclass MAY override this modifier for better funds management.
    /// (e.g. send to the EntryPoint more than the minimum required, so that in future transactions
    /// it will not be required to send again)
    ///
    /// `missingAccountFunds` is the minimum value this modifier should send the EntryPoint,
    /// which MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
    modifier payPrefund(uint256 missingAccountFunds) virtual {
        _;
        /// @solidity memory-safe-assembly
        assembly {
            if missingAccountFunds {
                // Ignore failure (it's EntryPoint's job to verify, not the account's).
                pop(call(gas(), caller(), missingAccountFunds, codesize(), 0x00, codesize(), 0x00))
            }
        }
    }
}
