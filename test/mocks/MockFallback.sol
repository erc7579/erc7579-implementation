// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IFallback } from "src/interfaces/IERC7579Module.sol";
import { IERC7579Account, Execution } from "src/interfaces/IERC7579Account.sol";
import { ExecutionLib } from "src/lib/ExecutionLib.sol";
import { ModeLib } from "src/lib/ModeLib.sol";

import "forge-std/console2.sol";

contract MockFallback is IFallback {
    function delegateCallTarget(uint256 param)
        public
        view
        returns (uint256 _param, address sender, address _this)
    {
        console2.log(
            "delegateCallTarget called with param: %s msg.sender: %s this: %s",
            param,
            msg.sender,
            address(this)
        );
        return (param, msg.sender, address(this));
    }

    function callTarget(uint256 param)
        public
        view
        returns (uint256 _param, address sender, address er2771Sender, address _this)
    {
        console2.log(
            "callTarget called with param: %s msg.sender: %s this: %s",
            param,
            msg.sender,
            address(this)
        );
        return (param, msg.sender, _msgSender(), address(this));
    }

    function staticCallTarget(uint256 param)
        public
        view
        returns (uint256 _param, address sender, address er2771Sender, address _this)
    {
        console2.log(
            "staticCall called with param: %s msg.sender: %s this: %s",
            param,
            msg.sender,
            address(this)
        );
        return (param, msg.sender, _msgSender(), address(this));
    }

    function _msgSender() internal pure returns (address sender) {
        // The assembly code is more direct than the Solidity version using `abi.decode`.
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
        /* solhint-enable no-inline-assembly */
    }

    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function isModuleType(uint256 typeID) external view override returns (bool) { }

    function isInitialized(address smartAccount) external view override returns (bool) { }
}
