// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract AccountBase {
    error Unauthorized();
    /////////////////////////////////////////////////////
    // Access Control
    ////////////////////////////////////////////////////

    modifier onlyEntryPoint() virtual {
        if (msg.sender != entryPoint()) revert Unauthorized();
        _;
    }

    function entryPoint() public view virtual returns (address) {
        return 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    }
}
