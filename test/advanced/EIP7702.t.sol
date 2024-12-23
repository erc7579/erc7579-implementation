// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "src/interfaces/IERC7579Account.sol";
import { MockTarget } from "../mocks/MockTarget.sol";
import { MockDelegateTarget } from "../mocks/MockDelegateTarget.sol";
import { ExecutionLib } from "src/lib/ExecutionLib.sol";
import {
    ModeLib,
    ModeCode,
    CallType,
    ExecType,
    ModeSelector,
    ModePayload,
    CALLTYPE_DELEGATECALL,
    EXECTYPE_DEFAULT,
    MODE_DEFAULT
} from "src/lib/ModeLib.sol";
import "./TestBaseUtilAdvanced.t.sol";
import { HashLib } from "src/lib/HashLib.sol";
import { ECDSA } from "solady/utils/ECDSA.sol";
import {
    MODULE_TYPE_VALIDATOR,
    MODULE_TYPE_EXECUTOR,
    MODULE_TYPE_HOOK
} from "src/core/ModuleManager.sol";
import { MockHook } from "../mocks/MockHook.sol";

contract EIP7702 is TestBaseUtilAdvanced {
    using ECDSA for bytes32;

    MockDelegateTarget delegateTarget;

    function setUp() public override {
        super.setUp();

        delegateTarget = new MockDelegateTarget();
    }

    function _doEIP7702(address account) internal {
        etch(account, address(implementation).code);
    }

    function _getInitData() internal view returns (bytes memory) {
        // Create config for initial modules
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(defaultValidator), "");
        BootstrapConfig[] memory executors = makeBootstrapConfig(address(defaultExecutor), "");
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = makeBootstrapConfig(address(0), "");

        return bootstrapSingleton._getInitMSACalldata(validators, executors, hook, fallbacks);
    }

    function _getSignature(
        uint256 eoaKey,
        PackedUserOperation memory userOp
    )
        internal
        view
        returns (bytes memory)
    {
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaKey, hash.toEthSignedMessageHash());
        return abi.encodePacked(r, s, v);
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
        uint256 eoaKey = uint256(8);
        address account = vm.addr(eoaKey);
        vm.deal(account, 100 ether);

        uint256 nonce = getNonce(account, address(defaultValidator));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(account);
        userOp.nonce = nonce;
        userOp.callData = userOpCalldata;

        userOp.signature = _getSignature(eoaKey, userOp);
        _doEIP7702(account);

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Send the userOp to the entrypoint
        entrypoint.handleOps(userOps, payable(address(0x69)));

        // Assert that the value was set ie that execution was successful
        assertTrue(target.value() == 1337);
        return account;
    }

    function test_initializeAndExecSingle() public returns (address) {
        // Get the account, initcode and nonce
        uint256 eoaKey = uint256(8);
        address account = vm.addr(eoaKey);
        vm.deal(account, 100 ether);

        // Create calldata for the account to execute
        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1337);

        bytes memory initData = _getInitData();

        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution({
            target: account,
            value: 0,
            callData: abi.encodeCall(MSAAdvanced.initializeAccount, initData)
        });
        executions[1] = Execution({ target: address(target), value: 0, callData: setValueOnTarget });

        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions))
        );

        uint256 nonce = getNonce(account, address(defaultValidator));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(account);
        userOp.nonce = nonce;
        userOp.callData = userOpCalldata;

        userOp.signature = _getSignature(eoaKey, userOp);
        _doEIP7702(account);

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
        uint256 eoaKey = uint256(8);
        address account = vm.addr(eoaKey);
        vm.deal(account, 100 ether);

        uint256 nonce = getNonce(account, address(defaultValidator));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(account);
        userOp.nonce = nonce;
        userOp.callData = userOpCalldata;

        userOp.signature = _getSignature(eoaKey, userOp);
        _doEIP7702(account);

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
        address account = test_initializeAndExecSingle();

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
        address account = test_initializeAndExecSingle();

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

    function test_delegateCall() public {
        // Create calldata for the account to execute
        address valueTarget = makeAddr("valueTarget");
        uint256 value = 1 ether;
        bytes memory sendValue =
            abi.encodeWithSelector(MockDelegateTarget.sendValue.selector, valueTarget, value);

        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encode(
                    CALLTYPE_DELEGATECALL, EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00)
                ),
                abi.encodePacked(address(delegateTarget), sendValue)
            )
        );

        // Get the account, initcode and nonce
        uint256 eoaKey = uint256(8);
        address account = vm.addr(eoaKey);
        vm.deal(account, 100 ether);

        uint256 nonce = getNonce(account, address(defaultValidator));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(account);
        userOp.nonce = nonce;
        userOp.callData = userOpCalldata;

        userOp.signature = _getSignature(eoaKey, userOp);
        _doEIP7702(account);

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Send the userOp to the entrypoint
        entrypoint.handleOps(userOps, payable(address(0x69)));

        // Assert that the value was set ie that execution was successful
        assertTrue(valueTarget.balance == value);
    }

    function test_delegateCall_fromExecutor() public {
        address account = test_initializeAndExecSingle();

        // Create calldata for the account to execute
        address valueTarget = makeAddr("valueTarget");
        uint256 value = 1 ether;
        bytes memory sendValue =
            abi.encodeWithSelector(MockDelegateTarget.sendValue.selector, valueTarget, value);

        // Execute the delegatecall via the executor
        defaultExecutor.execDelegatecall(
            IERC7579Account(address(account)), abi.encodePacked(address(delegateTarget), sendValue)
        );

        // Assert that the value was set ie that execution was successful
        assertTrue(valueTarget.balance == value);
    }

    function test_onRedelegation() public {
        address account = test_initializeAndExecSingle();

        MockHook hook = new MockHook();

        vm.prank(address(entrypoint));
        IMSA(account).installModule(MODULE_TYPE_HOOK, address(hook), "");

        assertTrue(
            IMSA(account).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(defaultValidator), "")
        );
        assertTrue(
            IMSA(account).isModuleInstalled(MODULE_TYPE_EXECUTOR, address(defaultExecutor), "")
        );
        assertTrue(IMSA(account).isModuleInstalled(MODULE_TYPE_HOOK, address(hook), ""));
        // storage is cleared
        vm.prank(address(account));
        IMSA(account).onRedelegation();
        assertFalse(
            IMSA(account).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(defaultValidator), "")
        );
        assertFalse(
            IMSA(account).isModuleInstalled(MODULE_TYPE_EXECUTOR, address(defaultExecutor), "")
        );
        assertFalse(IMSA(account).isModuleInstalled(MODULE_TYPE_HOOK, address(hook), ""));

        // account is properly initialized to install modules again
        vm.startPrank(address(entrypoint));
        IMSA(account).installModule(MODULE_TYPE_VALIDATOR, address(defaultValidator), "");
        IMSA(account).installModule(MODULE_TYPE_EXECUTOR, address(defaultExecutor), "");
        IMSA(account).installModule(MODULE_TYPE_HOOK, address(hook), "");

        vm.stopPrank();
        assertTrue(
            IMSA(account).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(defaultValidator), "")
        );
        assertTrue(
            IMSA(account).isModuleInstalled(MODULE_TYPE_EXECUTOR, address(defaultExecutor), "")
        );
        assertTrue(IMSA(account).isModuleInstalled(MODULE_TYPE_HOOK, address(hook), ""));
    }
}
