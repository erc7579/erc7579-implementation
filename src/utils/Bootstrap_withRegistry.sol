// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../core/ModuleManager.sol";
import "../core/Fallback.sol";
import "../core/HookManager.sol";
import "../core/RegistryAdapter.sol";

import "../interfaces/IModule.sol";
import { BootstrapConfig } from "./Bootstrap.sol";

contract Bootstrap is ModuleManager, Fallback, HookManager, RegistryAdapter {
    function singleInitMSA(
        IModule validator,
        bytes calldata data,
        address _registry,
        address _attester
    )
        external
    {
        _initModuleManager();

        // init validator
        _installValidator(address(validator), data);

        // init registry
        _setRegistry(IERC7484Registry(_registry));
        _setAttester(_attester);
    }

    function initMSA(
        BootstrapConfig[] calldata _validators,
        BootstrapConfig[] calldata _executors,
        BootstrapConfig calldata _fallback,
        address _registry,
        address _attester
    )
        external
    {
        _initModuleManager();

        // init registry
        _setRegistry(IERC7484Registry(_registry));
        _setAttester(_attester);

        // init validators
        for (uint256 i; i < _validators.length; i++) {
            address validator = address(_validators[i].module);
            _enforceRegistryCheck(validator);
            _installValidator(validator, _validators[i].data);
        }

        // init executors
        for (uint256 i; i < _executors.length; i++) {
            address executor = address(_executors[i].module);
            _enforceRegistryCheck(executor);
            _installExecutor(address(executor), _executors[i].data);
        }

        // init fallback
        if (address(_fallback.module) != address(0)) {
            address fallbackModule = address(_fallback.module);
            _enforceRegistryCheck(fallbackModule);
            _setFallback(fallbackModule);
        }
    }

    function _getInitMSACalldata(
        BootstrapConfig[] calldata _validators,
        BootstrapConfig[] calldata _executors,
        BootstrapConfig calldata _fallback,
        address _registry,
        address _attester
    )
        external
        view
        returns (bytes memory init)
    {
        init = abi.encode(
            address(this),
            abi.encodeCall(this.initMSA, (_validators, _executors, _fallback, _registry, _attester))
        );
    }

    function supportsInterface(bytes4 interfaceID)
        public
        pure
        virtual
        override(HookManager, ModuleManager)
        returns (bool)
    {
        return false;
    }
}
