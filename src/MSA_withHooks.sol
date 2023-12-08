pragma solidity ^0.8.23;

import "./MSA.sol";
import "./core/HookManager.sol";

/**
 * @title reference implementation of the minimal modular smart account with Hook Extension
 * @author zeroknots.eth | rhinestone.wtf
 */
contract MSAHooks is MSA, HookManager {
    error HookPostCheckFailed();

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

        bytes memory hookData = hook.preCheck(msg.sender, target, value, callData);
        result = super._execute(target, value, callData);
        if (!hook.postCheck(hookData)) revert HookPostCheckFailed();
    }
}
