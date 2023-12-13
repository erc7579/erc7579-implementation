// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./MSA_ValidatorInSignature.sol";
import "../core/HookManager.sol";

/**
 * @title reference implementation of the minimal modular smart account with Hook Extension
 * @author zeroknots.eth | rhinestone.wtf
 */
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
        bytes32 slot = HOOKMANAGER_STORAGE_LOCATION;
        IHook hook;
        assembly {
            hook := sload(slot)
        }
        bool isHookSet = address(hook) != address(0);

        if (isHookSet) {
            // if hook is set, execute preCheck, then execute call, then execute postCheck
            bytes memory hookData = hook.preCheck(msg.sender, msg.data);
            result = super._execute(target, value, callData);
            if (!hook.postCheck(hookData)) revert HookPostCheckFailed();
        } else {
            // if hook is not set, execute call
            result = super._execute(target, value, callData);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(MSABase, HookManager)
        returns (bool)
    {
        return interfaceId == type(IAccountConfig_Hook).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
