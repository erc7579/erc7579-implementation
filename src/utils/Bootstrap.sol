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
        BootstrapConfig[] calldata $valdiators,
        BootstrapConfig[] calldata $executors,
        BootstrapConfig calldata _hook,
        BootstrapConfig[] calldata _fallbacks
    )
        external
    {
        // init validators
        for (uint256 i; i < $valdiators.length; i++) {
            _installValidator($valdiators[i].module, $valdiators[i].data);
        }

        // init executors
        for (uint256 i; i < $executors.length; i++) {
            if ($executors[i].module == address(0)) continue;
            _installExecutor($executors[i].module, $executors[i].data);
        }

        // init hook
        if (_hook.module != address(0)) {
            _installHook(_hook.module, _hook.data);
        }

        // init fallback
        for (uint256 i; i < _fallbacks.length; i++) {
            if (_fallbacks[i].module == address(0)) continue;
            _installFallbackHandler(_fallbacks[i].module, _fallbacks[i].data);
        }
    }

    function _getInitMSACalldata(
        BootstrapConfig[] calldata $valdiators,
        BootstrapConfig[] calldata $executors,
        BootstrapConfig calldata _hook,
        BootstrapConfig[] calldata _fallbacks
    )
        external
        view
        returns (bytes memory init)
    {
        init = abi.encode(
            address(this),
            abi.encodeCall(this.initMSA, ($valdiators, $executors, _hook, _fallbacks))
        );
    }
}
