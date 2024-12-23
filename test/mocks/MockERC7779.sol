// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ERC7779Adapter } from "src/core/ERC7779Adapter.sol";

contract MockERC7779 is ERC7779Adapter {
    function addStorageBase(bytes32 storageBase) external {
        _addStorageBase(storageBase);
    }

    function _onRedelegation() internal override {
        // do nothing
    }
}
