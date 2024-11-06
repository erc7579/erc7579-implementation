// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import "src/MSAFactory.sol";
import { Bootstrap, BootstrapConfig } from "src/utils/Bootstrap.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
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
import "src/interfaces/IERC7579Account.sol";
import { ExecutionLib } from "src/lib/ExecutionLib.sol";

import "forge-std/console2.sol";

/**
 * @title DeployAccount
 * @author @kopy-kat
 */
contract DeployAccountScript is Script {
    function run() public {
        MSAFactory factory = MSAFactory(address(0xeffF0157a29286b1B66f59184E1Cc8C95bb69327));
        Bootstrap bootstrap =
            Bootstrap(payable(address(0xC33673E6a02ac64B90f2b8FaC58f88309DB6238B)));
        address initialValidator = address(0x11D02847245Df7cF19f48C8907ace59289D8aCEe);

        bytes32 salt = bytes32(uint256(1));

        // Create config for initial modules
        BootstrapConfig[] memory validators = new BootstrapConfig[](1);
        validators[0] = BootstrapConfig({ module: initialValidator, data: "" });
        BootstrapConfig[] memory executors = new BootstrapConfig[](0);
        BootstrapConfig memory hook;
        BootstrapConfig[] memory fallbacks = new BootstrapConfig[](1);

        // Create initcode and salt to be sent to Factory
        bytes memory _initCode =
            bootstrap._getInitMSACalldata(validators, executors, hook, fallbacks);

        // Get address of new account
        address account = factory.getAddress(salt, _initCode);

        // Pack the initcode to include in the userOp
        bytes memory initCode = abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(factory.createAccount.selector, salt, _initCode)
        );

        IEntryPoint entryPoint = IEntryPoint(address(0x0000000071727De22E5E9d8BAf0edAc6f37da032));

        // Create the userOp and add the data
        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(account);

        uint192 key = uint192(bytes24(bytes20(address(initialValidator))));
        userOp.nonce = entryPoint.getNonce(address(account), key);

        userOp.initCode = initCode;
        userOp.callData = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleSingle(), ExecutionLib.encodeSingle(address(0), uint256(1), ""))
        );

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        console2.log(account);

        vm.startBroadcast(vm.envUint("PK"));

        entryPoint.handleOps(userOps, payable(address(0x69)));

        vm.stopBroadcast();
    }

    function getDefaultUserOp() internal pure returns (PackedUserOperation memory userOp) {
        userOp = PackedUserOperation({
            sender: address(0),
            nonce: 0,
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
            preVerificationGas: 2e6,
            gasFees: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
            paymasterAndData: bytes(""),
            signature: abi.encodePacked(hex"41414141")
        });
    }
}
