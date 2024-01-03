// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "../interfaces/IModule.sol";

abstract contract ModuleBase is IModule {
    uint256 constant TYPE_VALIDATOR = 1;
    uint256 constant TYPE_EXECUTOR = 2;
    uint256 constant TYPE_FALLBACK = 3;
    uint256 constant TYPE_HOOK = 4;
    function name() external pure virtual returns (string memory);
    function version() external pure virtual returns (string memory);
}
