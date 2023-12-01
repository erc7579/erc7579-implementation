// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "src/interfaces/IModule.sol";
import { IMSA } from "src/interfaces/IMSA.sol";

contract MockExecutor is IExecutor {
    function enable(bytes calldata data) external override { }

    function disable(bytes calldata data) external override { }

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
}
