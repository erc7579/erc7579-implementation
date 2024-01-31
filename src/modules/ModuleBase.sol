// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { EncodedModuleTypes, ModuleType, ModuleTypeLib } from "../lib/ModuleTypeLib.sol";
import { IModule } from "../interfaces/IERC7579Module.sol";

abstract contract ModuleBase is IModule {
    EncodedModuleTypes public immutable MODULE_TYPES;

    constructor(ModuleType[] memory moduleTypes) {
        MODULE_TYPES = ModuleTypeLib.bitEncode(moduleTypes);
    }

    function isModuleType(uint256 _isModuleType) public view returns (bool) {
        return ModuleTypeLib.isType(MODULE_TYPES, ModuleType.wrap(_isModuleType));
    }

    function getModuleTypes() public view returns (EncodedModuleTypes) {
        return MODULE_TYPES;
    }
}
