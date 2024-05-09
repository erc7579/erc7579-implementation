// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC7579Account, Execution } from "src/interfaces/IERC7579Account.sol";
import "src/interfaces/IERC7579Module.sol";
import { MockTarget } from "./mocks/MockTarget.sol";
import {
    CallType,
    CALLTYPE_SINGLE,
    CALLTYPE_DELEGATECALL,
    CALLTYPE_STATIC
} from "../src/lib/ModeLib.sol";
import { ExecutionLib } from "src/lib/ExecutionLib.sol";
import {
    ModeLib, ModeCode, CallType, ExecType, ModeSelector, ModePayload
} from "src/lib/ModeLib.sol";
import { TestBaseUtil, PackedUserOperation } from "./TestBaseUtil.t.sol";
import { Vm } from "forge-std/Vm.sol";
import { MockFallback } from "./mocks/MockFallback.sol";
import { IMSA } from "src/interfaces/IMSA.sol";

contract EIP7702StorageTest is TestBaseUtil {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    MockFallback fallbackModule;

    /*//////////////////////////////////////////////////////////////////////////
                                    VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address account;
    bytes initData;

    /*//////////////////////////////////////////////////////////////////////////
                                      SETUP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();

        account = makeAddr("eoa");
        vm.label(account, "Account");
        vm.deal(account, 10 ether);

        initData = getInitData();

        fallbackModule = new MockFallback();
        vm.label(address(fallbackModule), "MockFallback");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      UTILS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mockEIP7702() {
        vm.etch(account, address(implementation).code);
        _;
        vm.etch(account, "");
    }

    modifier isEIP7702StorageCompliant() {
        vm.startStateDiffRecording();
        _;
        Vm.AccountAccess[] memory records = vm.stopAndReturnStateDiff();

        for (uint256 i = 0; i < records.length; i++) {
            Vm.AccountAccess memory record = records[i];
            if (record.account == account) {
                assertEq(record.storageAccesses.length, 0);
            }
        }
    }

    function setUpAccount() internal {
        // Encode the call into the calldata for the userOp
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleSingle(), ExecutionLib.encodeSingle(address(1), uint256(1), ""))
        );

        // Get nonce
        uint256 nonce = getNonce(account, address(defaultValidator));

        // Get signature
        bytes memory signature = hex"41414141";

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = account;
        userOp.nonce = nonce;
        userOp.callData = userOpCalldata;
        userOp.signature = abi.encode(signature, initData);

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Send the userOp to the entrypoint
        entrypoint.handleOps(userOps, payable(address(0x69)));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_execSingle() public mockEIP7702 isEIP7702StorageCompliant {
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

        // Get nonce
        uint256 nonce = getNonce(account, address(defaultValidator));

        // Get signature
        bytes memory signature = hex"41414141";

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = account;
        userOp.nonce = nonce;
        userOp.callData = userOpCalldata;
        userOp.signature = abi.encode(signature, initData);

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Send the userOp to the entrypoint
        entrypoint.handleOps(userOps, payable(address(0x69)));

        // Assert that the value was set ie that execution was successful
        assertTrue(target.value() == 1337);
    }

    function test_execBatch() public mockEIP7702 isEIP7702StorageCompliant {
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

        // Get nonce
        uint256 nonce = getNonce(account, address(defaultValidator));

        // Get signature
        bytes memory signature = hex"41414141";

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = account;
        userOp.nonce = nonce;
        userOp.callData = userOpCalldata;
        userOp.signature = abi.encode(signature, initData);

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Send the userOp to the entrypoint
        entrypoint.handleOps(userOps, payable(address(0x69)));

        // Assert that the value was set ie that execution was successful
        assertTrue(target.value() == 1337);
        assertTrue(target2.balance == target2Amount);
    }

    function test_execSingleFromExecutor() public mockEIP7702 isEIP7702StorageCompliant {
        setUpAccount();

        bytes[] memory ret = defaultExecutor.executeViaAccount(
            IERC7579Account(account),
            address(target),
            0,
            abi.encodePacked(MockTarget.setValue.selector, uint256(1338))
        );

        assertEq(ret.length, 1);
        assertEq(abi.decode(ret[0], (uint256)), 1338);
    }

    function test_execBatchFromExecutor() public mockEIP7702 isEIP7702StorageCompliant {
        setUpAccount();

        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1338);
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution({ target: address(target), value: 0, callData: setValueOnTarget });
        executions[1] = Execution({ target: address(target), value: 0, callData: setValueOnTarget });
        bytes[] memory ret =
            defaultExecutor.execBatch({ account: IERC7579Account(account), execs: executions });

        assertEq(ret.length, 2);
        assertEq(abi.decode(ret[0], (uint256)), 1338);
    }

    function test_execOnFallback() public mockEIP7702 isEIP7702StorageCompliant {
        setUpAccount();

        vm.startPrank(account);
        IMSA(account).installModule(
            MODULE_TYPE_FALLBACK,
            address(fallbackModule),
            abi.encodePacked(MockFallback.callTarget.selector, CALLTYPE_SINGLE, "")
        );

        IMSA(account).installModule(
            MODULE_TYPE_FALLBACK,
            address(fallbackModule),
            abi.encodePacked(MockFallback.staticCallTarget.selector, CALLTYPE_STATIC, "")
        );

        vm.stopPrank();

        uint256 ret;
        address sender;
        address _this;
        address erc2771;

        (ret, sender, erc2771, _this) = MockFallback(account).callTarget(1337);
        assertEq(ret, 1337);
        assertEq(sender, account, "msg.sender should be the account");
        assertEq(erc2771, address(this), "erc2771 should be the test contract");
        assertEq(_this, address(fallbackModule), "this should be the fallback module");

        (ret, sender, erc2771, _this) = MockFallback(account).staticCallTarget(1337);
        assertEq(ret, 1337);
        assertEq(sender, account, "msg.sender should be the account");
        assertEq(erc2771, address(this), "erc2771 should be the test contract");
        assertEq(_this, address(fallbackModule), "this should be the fallback module");

        vm.startPrank(account);
        IMSA(account).uninstallModule(
            MODULE_TYPE_FALLBACK,
            address(fallbackModule),
            abi.encodePacked(MockFallback.callTarget.selector, "")
        );
        vm.stopPrank();

        vm.expectRevert();
        MockFallback(account).callTarget(1337);
    }
}
