// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "src/accountExamples/MSA_withRegistryExtension.sol";
import "src/interfaces/IMSA.sol";
import "src/MSAFactory.sol";
import "./Bootstrap.t.sol";
import { MockValidator } from "./mocks/MockValidator.sol";
import { MockExecutor } from "./mocks/MockExecutor.sol";
import { MockTarget } from "./mocks/MockTarget.sol";
import { ECDSAValidator } from "src/modules/ECDSAValidator.sol";
import { Bootstrap as Bootstrap_withRegistry } from "src/utils/Bootstrap_withRegistry.sol";
import { MockRegistry } from "./mocks/MockRegistry.sol";

import "./dependencies/EntryPoint.sol";

contract MSA_withRegistryExtensionTest is BootstrapUtil, Test {
    // singletons
    MSA implementation;
    MSAFactory factory;
    IEntryPoint entrypoint = IEntryPoint(ENTRYPOINT_ADDR);

    MockValidator defaultValidator;
    MockExecutor defaultExecutor;
    ECDSAValidator ecdsaValidator;

    MockTarget target;

    MockRegistry registry;
    address trustedAttester;

    Bootstrap_withRegistry bootstrapSingleton_withRegistry;

    MSA account;

    function setUp() public virtual {
        etchEntrypoint();
        implementation = new MSA();
        factory = new MSAFactory(address(implementation));

        // setup module singletons
        defaultExecutor = new MockExecutor();
        defaultValidator = new MockValidator();
        target = new MockTarget();
        ecdsaValidator = new ECDSAValidator();

        registry = new MockRegistry();
        trustedAttester = address(0x69);

        bootstrapSingleton_withRegistry = new Bootstrap_withRegistry();
        vm.deal(address(account), 1 ether);
    }

    function test_execVia4337__WithInitCode() public {
        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1337);
        bytes memory execFunction =
            abi.encodeCall(IExecution.execute, (address(target), 0, setValueOnTarget));

        // setup account init config
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(defaultValidator), "");
        BootstrapConfig[] memory executors = makeBootstrapConfig(address(defaultExecutor), "");
        BootstrapConfig memory fallbackHandler = _makeBootstrapConfig(address(0), "");

        bytes memory initCode = bootstrapSingleton_withRegistry._getInitMSACalldata(
            validators, executors, fallbackHandler, address(registry), trustedAttester
        );

        address newAccount = factory.getAddress(0, initCode);
        vm.deal(newAccount, 1 ether);

        uint192 key = uint192(bytes24(bytes20(address(defaultValidator))));
        uint256 nonce = entrypoint.getNonce(address(account), key);

        UserOperation memory userOp = UserOperation({
            sender: address(newAccount),
            nonce: nonce,
            initCode: abi.encodePacked(
                address(factory), abi.encodeWithSelector(factory.createAccount.selector, 0, initCode)
                ),
            callData: execFunction,
            callGasLimit: 2e6,
            verificationGasLimit: 2e6,
            preVerificationGas: 2e6,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: hex"41414141"
        });

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entrypoint.handleOps(userOps, payable(address(0x69)));

        assertTrue(target.value() == 1337);
    }
}
