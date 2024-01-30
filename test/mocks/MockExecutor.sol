// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IExecutor } from "src/interfaces/IERC7579Module.sol";
import { IERC7579Account } from "src/interfaces/IERC7579Account.sol";
import { ExecutionLib } from "src/lib/ExecutionLib.sol";
import { ModeLib } from "src/lib/ModeLib.sol";

contract MockExecutor is IExecutor {
    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function executeViaAccount(
        IERC7579Account account,
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
    {
        account.execute(
            ModeLib.encodeSimpleSingle(), ExecutionLib.encodeSingle(target, value, callData)
        );
    }

    function isModuleType(uint256 typeID) external view returns (bool) {
        return typeID == 2;
    }

    function getModuleTypes() external pure returns (uint256) {
        return 1 << 2;
    }

    function isInitialized(address smartAccount) external pure returns (bool) {
        return false;
    }
}
