// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "src/interfaces/IERC7579Account.sol";
import "src/interfaces/IERC7579Module.sol";
import { MockTarget } from "./mocks/MockTarget.sol";
import {
    CallType,
    CALLTYPE_SINGLE,
    CALLTYPE_DELEGATECALL,
    CALLTYPE_STATIC
} from "../src/lib/ModeLib.sol";
import { MockFallback } from "./mocks/MockFallback.sol";
import { ExecutionLib } from "src/lib/ExecutionLib.sol";
import {
    ModeLib, ModeCode, CallType, ExecType, ModeSelector, ModePayload
} from "src/lib/ModeLib.sol";
import "./TestBaseUtil.t.sol";

contract MSATest is TestBaseUtil {
    MockFallback fallbackModule;

    function setUp() public override {
        super.setUp();
        fallbackModule = new MockFallback();
    }

    function test_execSingle() public returns (address) {
        // Create calldata for the account to execute
        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1337);

        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(target), uint256(0), setValueOnTarget)
            )
        );

        // Get the account, initcode and nonce
        (address account, bytes memory initCode) = getAccountAndInitCode();
        uint256 nonce = getNonce(account, address(defaultValidator));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(account);
        userOp.nonce = nonce;
        userOp.initCode = initCode;
        userOp.callData = userOpCalldata;

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Send the userOp to the entrypoint
        entrypoint.handleOps(userOps, payable(address(0x69)));

        // Assert that the value was set ie that execution was successful
        assertTrue(target.value() == 1337);
        return account;
    }

    function test_execBatch() public {
        // Create calldata for the account to execute
        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1337);
        address target2 = address(0x420);
        uint256 target2Amount = 1 wei;

        // Create the executions
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution({ target: address(target), value: 0, callData: setValueOnTarget });
        executions[1] = Execution({ target: target2, value: target2Amount, callData: "" });

        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );

        // Get the account, initcode and nonce
        (address account, bytes memory initCode) = getAccountAndInitCode();
        uint256 nonce = getNonce(account, address(defaultValidator));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(account);
        userOp.nonce = nonce;
        userOp.initCode = initCode;
        userOp.callData = userOpCalldata;

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Send the userOp to the entrypoint
        entrypoint.handleOps(userOps, payable(address(0x69)));

        // Assert that the value was set ie that execution was successful
        assertTrue(target.value() == 1337);
        assertTrue(target2.balance == target2Amount);
    }

    function test_execSingleFromExecutor() public {
        address account = test_execSingle();

        bytes[] memory ret = defaultExecutor.executeViaAccount(
            IERC7579Account(address(account)),
            address(target),
            0,
            abi.encodePacked(MockTarget.setValue.selector, uint256(1338))
        );

        assertEq(ret.length, 1);
        assertEq(abi.decode(ret[0], (uint256)), 1338);
    }

    function test_execBatchFromExecutor() public {
        address account = test_execSingle();

        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1338);
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution({ target: address(target), value: 0, callData: setValueOnTarget });
        executions[1] = Execution({ target: address(target), value: 0, callData: setValueOnTarget });
        bytes[] memory ret = defaultExecutor.execBatch({
            account: IERC7579Account(address(account)),
            execs: executions
        });

        assertEq(ret.length, 2);
        assertEq(abi.decode(ret[0], (uint256)), 1338);
    }

    function test_execOnFallback() public {
        IMSA account = IMSA(test_execSingle());

        vm.startPrank(address(account));
        account.installModule(
            MODULE_TYPE_FALLBACK,
            address(fallbackModule),
            abi.encodePacked(MockFallback.callTarget.selector, CALLTYPE_SINGLE, "")
        );

        account.installModule(
            MODULE_TYPE_FALLBACK,
            address(fallbackModule),
            abi.encodePacked(MockFallback.delegateCallTarget.selector, CALLTYPE_DELEGATECALL, "")
        );

        account.installModule(
            MODULE_TYPE_FALLBACK,
            address(fallbackModule),
            abi.encodePacked(MockFallback.staticCallTarget.selector, CALLTYPE_STATIC, "")
        );

        vm.stopPrank();

        uint256 ret;
        address sender;
        address _this;
        address erc2771;

        (ret, sender, erc2771, _this) = MockFallback(address(account)).callTarget(1337);
        assertEq(ret, 1337);
        assertEq(sender, address(account), "msg.sender should be the account");
        assertEq(erc2771, address(this), "erc2771 should be the test contract");
        assertEq(_this, address(fallbackModule), "this should be the fallback module");

        (ret, sender, erc2771, _this) = MockFallback(address(account)).staticCallTarget(1337);
        assertEq(ret, 1337);
        assertEq(sender, address(account), "msg.sender should be the account");
        assertEq(erc2771, address(this), "erc2771 should be the test contract");
        assertEq(_this, address(fallbackModule), "this should be the fallback module");

        (ret, sender, _this) = MockFallback(address(account)).delegateCallTarget(1337);
        assertEq(ret, 1337);
        assertEq(sender, address(this));
        assertEq(_this, address(account));

        vm.startPrank(address(account));
        account.uninstallModule(
            MODULE_TYPE_FALLBACK,
            address(fallbackModule),
            abi.encodePacked(MockFallback.callTarget.selector, "")
        );
        vm.stopPrank();

        vm.expectRevert();
        MockFallback(address(account)).callTarget(1337);
    }
}
