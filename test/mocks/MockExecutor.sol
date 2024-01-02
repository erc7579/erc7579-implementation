// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IExecutor } from "src/interfaces/IModule.sol";
import { IMSA } from "src/interfaces/IMSA.sol";

contract MockExecutor is IExecutor {
    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function executeViaAccount(
        IMSA account,
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        returns (bytes memory)
    {
        return account.execute(target, value, callData);
    }

    function isModuleType(uint256 typeID) external view returns (bool) {
        return typeID == 2;
    }
}
