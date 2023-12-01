pragma solidity ^0.8.23;

import "./MSA.sol";
import "./core/HookManager.sol";

contract MSAHooks is MSA, HookManager {
    function _execute(
        address target,
        uint256 value,
        bytes calldata callData
    )
        internal
        override
        returns (bytes memory result)
    {
        IHook hook = _hook;

        bytes memory hookData = hook.preCheck(target, value, callData);
        super._execute(target, value, callData);
        require(hook.postCheck(hookData), "HookManager: postCheck failed");
    }
}
