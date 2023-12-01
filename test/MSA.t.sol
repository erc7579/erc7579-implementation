// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "src/MSA.sol";
import { MockValidator } from "./mocks/MockValidator.sol";
import { MockExecutor } from "./mocks/MockExecutor.sol";
import { MockTarget } from "./mocks/MockTarget.sol";

import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import "./dependencies/EntryPoint.sol";

contract MSATest is Test {
    MSA account;

    MockValidator validator;
    MockExecutor executor;

    MockTarget target;

    IEntryPoint entrypoint = IEntryPoint(ENTRYPOINT_ADDR);

    function setUp() public {
        etchEntrypoint();
        account = new MSA();
        vm.deal(address(account), 100 ether);

        validator = new MockValidator();
        executor = new MockExecutor();

        target = new MockTarget();

        init();
    }

    function init() public {
        bytes memory initParams = abi.encode(address(validator));
        account.initializeAccount(initParams);
    }

    function testInit() public {
        assertTrue(account.isValidatorEnabled(address(validator)));
    }

    function testExecute() public {
        bytes memory executeThis = abi.encodeCall(MockTarget.setValue, 1337);

        bytes memory execFunction = abi.encodeCall(MSA.execute, (address(target), 0, executeThis));
        UserOperation memory userOp = UserOperation({
            sender: address(account),
            nonce: entrypoint.getNonce(address(account), 0),
            initCode: "",
            callData: execFunction,
            callGasLimit: 2e6,
            verificationGasLimit: 2e6,
            preVerificationGas: 2e6,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: abi.encodePacked(address(validator), hex"41414141")
        });

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entrypoint.handleOps(userOps, payable(address(0x69)));

        assertTrue(target.value() == 1337);
    }
}
