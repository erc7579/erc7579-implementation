// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../core/ModuleManager.sol";
import "../core/HookManager.sol";

import "../interfaces/IERC7579Module.sol";

struct BootstrapConfig {
    address module;
    bytes data;
}

contract Bootstrap is ModuleManager, HookManager {
    function singleInitMSA(IModule validator, bytes calldata data) external {
        // init validator
        _installValidator(address(validator), data);
    }

    /**
     * This function is intended to be called by the MSA with a delegatecall.
     * Make sure that the MSA already initilazed the linked lists in the ModuleManager prior to
     * calling this function
     */
    function initMSA(
        BootstrapConfig[] calldata _validators,
        BootstrapConfig[] calldata _executors,
        BootstrapConfig calldata _hook,
        BootstrapConfig calldata _fallback
    )
        external
    {
        // init validators
        for (uint256 i; i < _validators.length; i++) {
            _installValidator(_validators[i].module, _validators[i].data);
        }

        // init executors
        for (uint256 i; i < _executors.length; i++) {
            if (_executors[i].module == address(0)) continue;
            _installExecutor(_executors[i].module, _executors[i].data);
        }

        // init hook
        if (_hook.module != address(0)) {
            _installHook(_hook.module, _hook.data);
        }

        // init fallback
        if (_fallback.module != address(0)) {
            _installFallbackHandler(_fallback.module, _fallback.data);
        }
    }

    function _getInitMSACalldata(
        BootstrapConfig[] calldata _validators,
        BootstrapConfig[] calldata _executors,
        BootstrapConfig calldata _hook,
        BootstrapConfig calldata _fallback
    )
        external
        view
        returns (bytes memory init)
    {
        init = abi.encode(
            address(this), abi.encodeCall(this.initMSA, (_validators, _executors, _hook, _fallback))
        );
    }
}
