// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @dev Execution Interface of the minimal Modular Smart Account standard
 */
interface IMSA_Exec {
    error Unsupported();

    /**
     *
     * @dev Executes a transaction on behalf of the account.
     *         This function is intended to be called by ERC-4337 EntryPoint.sol
     * @dev MSA MUST implement this function signature. If functionality should not be supported, revert "Unsupported"!
     * @dev This function MUST revert if the call fails.
     * @param target The address of the contract to call.
     * @param value The value in wei to be sent to the contract.
     * @param callData The call data to be sent to the contract.
     * @return result The return data of the executed contract call.
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        returns (bytes memory result);

    /**
     *
     * @dev Executes a transaction via delegatecall on behalf of the account.
     *         This function is intended to be called by ERC-4337 EntryPoint.sol
     * @dev This function MUST revert if the call fails.
     * @dev MSA MUST implement this function signature. If functionality should not be supported, revert "Unsupported"!
     * @param target The address of the contract to call.
     * @param callData The call data to be sent to the contract.
     * @return result The return data of the executed contract call.
     */
    function executeDelegateCall(
        address target,
        bytes calldata callData
    )
        external
        returns (bytes memory result);

    /**
     *
     * @dev Executes a batched transaction via 'call' on behalf of the account.
     *         This function is intended to be called by ERC-4337 EntryPoint.sol
     * @dev This function MUST revert if the call fails.
     * @dev MSA MUST implement this function signature. If functionality should not be supported, revert "Unsupported"!
     * @param targets The addresses of the contract to call.
     * @param values The valuees in wei to be sent to the contract.
     * @param callDatas The call datas to be sent to the contract.
     * @return results The return data of the executed contract call.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata callDatas
    )
        external
        returns (bytes[] memory results);

    /**
     *
     * @dev Executes a transaction on behalf of the account.
     *         This function is intended to be called by an Executor module.
     * @dev This function MUST revert if the call fails.
     * @dev MSA MUST implement this function signature. If functionality should not be supported, revert "Unsupported"!
     * @param target The address of the contract to call.
     * @param value The value in wei to be sent to the contract.
     * @param callData The call data to be sent to the contract.
     * @return result The return data of the executed contract call.
     */
    function executeFromModule(
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        returns (bytes memory);

    /**
     *
     * @dev Executes a transaction via delegatecall on behalf of the account.
     *         This function is intended to be called by an Executor module.
     * @dev This function MUST revert if the call fails.
     * @dev MSA MUST implement this function signature. If functionality should not be supported, revert "Unsupported"!
     * @param targets The addresses of the contract to call.
     * @param values The valuees in wei to be sent to the contract.
     * @param callDatas The call datas to be sent to the contract.
     * @return results The return data of the executed contract call.
     */
    function executeBatchFromModule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata callDatas
    )
        external
        returns (bytes[] memory results);

    /**
     *
     * @dev Executes a transaction via delegatecall on behalf of the account.
     *         This function is intended to be called by an Executor module.
     * @dev This function MUST revert if the call fails.
     * @dev MSA MUST implement this function signature. If functionality should not be supported, revert "Unsupported"!
     * @param target The address of the contract to call.
     * @param callData The call data to be sent to the contract.
     * @return result The return data of the executed contract call.
     */
    function executeDelegateCallFromModule(
        address target,
        bytes memory callData
    )
        external
        returns (bytes memory);
}

/**
 * @dev Configuration Interface of the minimal Modular Smart Account standard
 */
interface IMSA_Config {
    event EnableValidator(address module);
    event DisableValidator(address module);

    event EnableExecutor(address module);
    event DisableExecutor(address module);

    /////////////////////////////////////////////////////
    //  Validator Modules
    ////////////////////////////////////////////////////
    /**
     * @dev Enables a Validator module on the account.
     * @dev Implement Authorization control of your chosing
     * @param validator The address of the Validator module to enable.
     * @param data any abi encoded further paramters needed
     */
    function enableValidator(address validator, bytes calldata data) external;

    /**
     * @dev Disables a Validator Module on the account.
     * @dev Implement Authorization control of your chosing
     * @param validator The address of the Validator module to enable.
     * @param data any abi encoded further paramters needed
     */
    function disableValidator(address validator, bytes calldata data) external;

    /**
     * @dev checks if specific validator module is enabled on the account
     * @param validator The address of the Validator module to enable.
     * returns bool if validator is enabled
     */
    function isValidatorEnabled(address validator) external view returns (bool);
    /////////////////////////////////////////////////////
    //  Executor Modules
    ////////////////////////////////////////////////////

    /**
     * @dev Enables a Executor module on the account.
     * @dev Implement Authorization control of your chosing
     * @param executor The address of the Validator module to enable.
     * @param data any abi encoded further paramters needed
     */
    function enableExecutor(address executor, bytes calldata data) external;

    /**
     * @dev Disable a Executor module on the account.
     * @dev Implement Authorization control of your chosing
     * @param executor The address of the Validator module to enable.
     * @param data any abi encoded further paramters needed
     */
    function disableExecutor(address executor, bytes calldata data) external;

    /**
     * @dev checks if specific executor module is enabled on the account
     * @param executor The address of the Executort module
     * returns bool if executor is enabled
     */
    function isExecutorEnabled(address executor) external view returns (bool);
    /////////////////////////////////////////////////////
    //  Fallback Modules
    ////////////////////////////////////////////////////
    /**
     * @dev Enables a Fallback module on the account.
     * @dev Implement Authorization control of your chosing
     */
    function enableFallback(address fallbackHandler, bytes calldata data) external;
    /**
     * @dev DisableExecutor
     *
     */
    function disableFallback(address fallbackHandler, bytes calldata data) external;
    /**
     * @dev checks if specific fallback handler is enabled on the account
     * @param fallbackHandler The address of the fallback handler module
     * returns bool if fallbackhandler is enabled
     */
    function isFallbackEnabled(address fallbackHandler) external view returns (bool);
}

interface IMSA is IMSA_Exec, IMSA_Config {
    /////////////////////////////////////////////////////
    //  Account Initialization
    ////////////////////////////////////////////////////

    /**
     * @dev initializes a MSA
     * @dev implement checks  that account can only be initialized once
     * @param data abi encoded init params
     */
    function initializeAccount(bytes calldata data) external;
}

/**
 * @dev Configuration Interface of the minimal Modular Smart Account Hook extention standard
 */
interface IMSA_ConfigExt is IMSA_Config {
    event EnableHook(address module);
    event DisableHook(address module);
    /////////////////////////////////////////////////////
    //  Hook Modules
    ////////////////////////////////////////////////////

    /**
     * @dev Enables a Hook module on the account.
     * @dev Implement Authorization control of your chosing
     * @param hook The address of the Hook module to enable.
     * @param data any abi encoded further paramters needed
     */
    function enableHook(address hook, bytes calldata data) external;

    /**
     * @dev Disable a Hook module on the account.
     * @dev Implement Authorization control of your chosing
     * @param hook The address of the hook module to enable.
     * @param data any abi encoded further paramters needed
     */
    function disableHook(address hook, bytes calldata data) external;

    /**
     * @dev checks if specific hook module is enabled on the account
     * @param hook The address of the Executort module to enable.
     * returns bool if hook is enabled
     */
    function isHookEnabled(address hook) external view returns (bool);
}
