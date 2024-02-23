// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script } from "forge-std/Script.sol";
import { MSAAdvanced } from "src/MSAAdvanced.sol";
import { MSAFactory } from "src/MSAFactory.sol";

/**
 * @title Deploy
 * @author @kopy-kat
 */
contract DeployScript is Script {
    function run() public {
        bytes32 salt = bytes32(uint256(0));

        vm.startBroadcast(vm.envUint("PK"));

        // Deploy Modules
        MSAAdvanced msaAdvanced = new MSAAdvanced{ salt: salt }();
        MSAFactory msaFactory = new MSAFactory{ salt: salt }(address(msaAdvanced));

        vm.stopBroadcast();
    }
}
