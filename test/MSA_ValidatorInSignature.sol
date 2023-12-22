// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "src/accountExamples/MSA_ValidatorInSignature.sol";
import "src/interfaces/IMSA.sol";
import "src/MSAFactory.sol";
import "./Bootstrap.t.sol";
import { MockValidator } from "./mocks/MockValidator.sol";
import { MockExecutor } from "./mocks/MockExecutor.sol";
import { MockTarget } from "./mocks/MockTarget.sol";
import { ECDSAValidator } from "src/modules/ECDSAValidator.sol";

import "./dependencies/EntryPoint.sol";

contract MSA_ValidatorInSignatureTest is BootstrapUtil, Test {
    // singletons
    MSA implementation;
    MSAFactory factory;
    IEntryPoint entrypoint = IEntryPoint(ENTRYPOINT_ADDR);

    MockValidator defaultValidator;
    MockExecutor defaultExecutor;

    ECDSAValidator ecdsaValidator;

    MockTarget target;

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

        // setup account init config
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(defaultValidator), "");
        BootstrapConfig[] memory executors = makeBootstrapConfig(address(defaultExecutor), "");
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig memory fallbackHandler = _makeBootstrapConfig(address(0), "");

        // create account
        account = MSA(
            factory.createAccount({
                salt: "1",
                initCode: bootstrapSingleton._getInitMSACalldata(
                    validators, executors, hook, fallbackHandler
                    )
            })
        );
        vm.deal(address(account), 1 ether);
    }

    function test_AccountFeatureDetectionExecutors() public {
        assertTrue(account.supportsInterface(type(IMSA).interfaceId));
    }

    function test_AccountFeatureDetectionConfig() public {
        assertTrue(account.supportsInterface(type(IAccountConfig).interfaceId));
    }

    function test_AccountFeatureDetectionConfigWHooks() public {
        assertFalse(account.supportsInterface(type(IAccountConfig_Hook).interfaceId));
    }

    function test_checkValidatorEnabled() public {
        assertTrue(account.isValidatorInstalled(address(defaultValidator)));
    }

    function test_checkExecutorEnabled() public {
        assertTrue(account.isExecutorInstalled(address(defaultExecutor)));
    }

    function test_execVia4337() public {
        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1337);
        bytes memory execFunction =
            abi.encodeCall(IExecution.execute, (address(target), 0, setValueOnTarget));

        uint192 key = uint192(bytes24(bytes20(address(defaultValidator))));
        uint256 nonce = entrypoint.getNonce(address(account), key);

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
            signature: abi.encodePacked(address(defaultValidator), hex"41414141")
        });

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entrypoint.handleOps(userOps, payable(address(0x69)));

        assertTrue(target.value() == 1337);
    }

    function test_execVia4337__WithInitCode() public {
        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1337);
        bytes memory execFunction =
            abi.encodeCall(IExecution.execute, (address(target), 0, setValueOnTarget));

        uint192 key = uint192(bytes24(bytes20(address(defaultValidator))));
        uint256 nonce = entrypoint.getNonce(address(account), key);

        bytes memory initCode = abi.encode(
            address(bootstrapSingleton),
            abi.encodeCall(
                Bootstrap.singleInitMSA, (defaultValidator, abi.encodePacked(address(0)))
            )
        );

        address newAccount = factory.getAddress(0, initCode);
        vm.deal(newAccount, 1 ether);

        UserOperation memory userOp = UserOperation({
            sender: address(newAccount),
            nonce: entrypoint.getNonce(address(account), 0),
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
            signature: abi.encodePacked(address(defaultValidator), hex"41414141")
        });

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entrypoint.handleOps(userOps, payable(address(0x69)));

        assertTrue(target.value() == 1337);
    }
}
