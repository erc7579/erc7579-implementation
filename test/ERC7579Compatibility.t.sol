// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "src/interfaces/IERC7579Account.sol";
import { MockTarget } from "./mocks/MockTarget.sol";
import { ExecutionLib } from "src/lib/ExecutionLib.sol";
import {
    ModeLib, ModeCode, CallType, ExecType, ModeSelector, ModePayload
} from "src/lib/ModeLib.sol";

import "./TestBaseUtil.t.sol";

contract ERC7579CompatibilityTest is TestBaseUtil {
    function setUp() public override {
        super.setUp();
    }

    // TODO

    // function test_AccountFeatureDetectionExecutors() public {
    //     assertTrue(account.supportsInterface(type(IERC7579Account).interfaceId));
    // }

    // function test_AccountFeatureDetectionConfig() public {
    //     assertTrue(account.supportsInterface(type(IAccountConfig).interfaceId));
    // }

    // function test_AccountFeatureDetectionConfigWHooks() public {
    //     assertFalse(account.supportsInterface(type(IAccountConfig_Hook).interfaceId));
    // }

    // function test_checkValidatorEnabled() public {
    //     assertTrue(account.isValidatorInstalled(address(defaultValidator)));
    // }

    // function test_checkExecutorEnabled() public {
    //     assertTrue(account.isExecutorInstalled(address(defaultExecutor)));
    // }

    // function test_receiveNativeToken() public {
    //     vm.deal(address(this), 100 ether);
    //     address(account).call{ value: 100 ether }("");
    //     assertTrue(address(account).balance >= 100 ether);
    // }
}
