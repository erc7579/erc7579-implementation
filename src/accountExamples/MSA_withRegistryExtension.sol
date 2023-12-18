// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { MSA as MSA_ValidatorInSignature, MSABase } from "./MSA_ValidatorInSignature.sol";
import "../core/RegistryAdapter.sol";

/**
 * @title reference implementation of the minimal modular smart account with registry extension
 * @author @kopy-kat | rhinestone.wtf
 */
contract MSA is MSA_ValidatorInSignature, RegistryAdapter {
    function executeFromExecutor(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        payable
        virtual
        override
        onlyExecutorModule
        onlySecureModule(msg.sender)
        returns (bytes memory returnData)
    {
        returnData = _execute(target, value, callData);
    }

    function executeBatchFromExecutor(Execution[] calldata executions)
        external
        payable
        virtual
        override
        onlyExecutorModule
        onlySecureModule(msg.sender)
        returns (bytes[] memory returnDatas)
    {
        returnDatas = _execute(executions);
    }

    /////////////////////////////////////////////////////
    // Unsafe Executions - Implement this with care!
    ////////////////////////////////////////////////////
    function executeDelegateCallFromExecutor(
        address target,
        bytes memory callData
    )
        external
        payable
        virtual
        override
        onlyExecutorModule
        onlySecureModule(msg.sender)
        returns (bytes memory)
    {
        revert Unsupported();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(MSABase)
        returns (bool)
    {
        // Todo
        // return interfaceId == type(IAccountConfig_Hook).interfaceId
        //     || super.supportsInterface(interfaceId);
    }
}
