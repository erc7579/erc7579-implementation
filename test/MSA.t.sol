// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "src/MSA.sol";
import { MockValidator } from "./mocks/MockValidator.sol";
import { MockExecutor } from "./mocks/MockExecutor.sol";
import { MockTarget } from "./mocks/MockTarget.sol";

address constant ENTRYPOINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

contract MSATest is Test {
    MSA account;

    MockValidator validator;
    MockExecutor executor;

    MockTarget target;

    function setUp() public {
        account = new MSA();

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
        vm.prank(ENTRYPOINT);
        account.execute({
            target: address(target),
            value: 0,
            callData: abi.encodeCall(MockTarget.setValue, 1337)
        });

        assertTrue(target.value() == 1337);
    }
}
