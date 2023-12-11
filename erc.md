---
title: Minimal Modular Smart Accounts
description: Minimally required interfaces and behavior for modular smart accounts and modules
author: #Todo
discussions-to: <tbd>
status: Draft
type: Standards Track
category: ERC
created: 2023-12-11
requires: ERC-165, ERC-1271, ERC-2771, ERC-4337
---

## Abstract

This proposal outlines the minimally required interfaces and behavior for modular smart accounts and modules to ensure interoperability accross implementations.

## Motivation

Contract accounts are gaining adoption with many new accounts being built in a modular fashion. These modular contract accounts (hereafter smart accounts) move functionality into external contracts (modules) in order to increase the speed and potential of innovation, to future-proof themselves and to allow customizability by developers and users. However, currently these smart accounts are built in vastly different ways, creating vendor lock-in and module fragmentation.

To solve these problems, we need to standardize the core interfaces for smart accounts and modules. However, it is highly important that this standardization is done with minimal impact on the implementation logic of the accounts, so that smart account vendors can innovate and compete, while also allowing a flourishing, multi-account-compatible module ecosystem.

The goals of this standard are:

- Define the most minimal interfaces for smart accounts and modules that ensure interoperability between accounts

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definitions

- **Smart account** - An [ERC-4337](./erc-4337.md) compliant smart contract account that has a modular architecture.
- **Module** - A smart contract with self-contained smart account functionality.
  - Validator: A module used during the ERC-4337 validation flow to determine if a `UserOperation` is valid.
  - Executor: A module that can execute transactions on behalf of the smart account via a callback.
  - Fallback Handler: A module that can extend the fallback functionality of a smart account.
- **Entrypoint** - A trusted singleton contract according to ERC-4337 specifications.

### Account

#### Validation

This Standard does not dictate how validator selection is implemented. However, should a smart account encode validator selection mechanisms in ERC-4337 `UserOperation` fields (i.e. `userOp.signature`), the smart account MUST sanitize the affected values before invoking the validator.

The smart account's `validateUserOp` function SHOULD return the return value of the validator.

#### Execution Behavior

To comply with this standard, smart accounts MUST implement the entire interface below. If an account implementation elects to not support any of the execution methods, it MUST revert, in order to avoid unpredictable behavior with fallbacks.

```solidity
interface IExecution {
    function execute(address target, uint256 value, bytes data) external returns (bytes memory result);
    function executeDelegateCall(address target, bytes data) external returns (bytes memory result);
    function executeBatch(address[] targets, uint256[] values, bytes[] data) external returns (bytes memory result);
    function executeFromModule(address target, uint256 value, bytes data) external returns (bytes memory result);
    function executeDelegateCallFromModule(address target, bytes data) external returns (bytes memory result);
    function executeBatchFromModule(address[] targets, uint256[] values, bytes[] data) external returns (bytes memory result);
}
```

For each of the functions in the interface, the smart account:

- MUST execute either `call` or `delegatecall` to all the provided targets with provided calldata and value (if applicable). If the function name includes `delegatecall`, the smart account MUST use `delegatecall`, otherwise the smart account MUST use `call`.
- MUST implement authorization control. For execute functions with `fromModule` in their name, this MUST be scoped to only allow enabled executors to call the function. For all other execute functions, this MUST be scoped to allow the ERC-4337 Entrypoint to call the function and MAY be scoped to allow `msg.sender == address(this)`.
- MUST revert if the call was not successful.

#### Account configurations

To comply with this standard, smart accounts MUST implement the entire interface below. If an account implementation elects to not support any of the configuration methods, it MUST revert, in order to avoid unpredictable behavior with fallbacks.

When enabling or disabling a module on a smart account, it

- MUST call the `onInstall` or `onUninstall` function on the module
- MUST pass the sanitized initialisation data to the module
- SHOULD store the module address during the enable process and remove it during the disable process
- MUST emit the relevant event for the module type
- MUST enforce authorization control on the relevant enable or disable function for the module type
- SHOULD allow for the relevant enable or disable function for the module type to be called by the account as part of a batch

When storing a module, the smart account MUST ensure that there is a way to differentiate between module types. For example, the smart account should be able to implement access control that only allows enabled executors, but not other enabled modules, to call the `executeFromModule` function.

```solidity
interface IAccountConfig {
    // VALIDATORS
    // Functions
    function enableValidator(address validator, bytes calldata data) external;
    function disableValidator(address validator, bytes calldata data) external;
    function isValidatorEnabled(address validator) external view returns (bool);

    // Events
    event EnableValidatorModule(address validator);
    event DisableValidatorModule(address validator);

    // EXECUTORS
    // Functions
    function enableExecutor(address executor, bytes calldata data) external;
    function disableExecutor(address executor, bytes calldata data) external;
    function isExecutorEnabled(address executor) external view returns (bool);

    // Events
    event EnableExecutorModule(address executor);
    event DisableExecutorModule(address executor);

    // FALLBACK HANDLERS
    // Functions
    function enableFallback(address fallbackHandler, bytes calldata data) external;
    function disableFallback(address fallbackHandler, bytes calldata data) external;
    function isFallbackEnabled(address fallbackHandler) external view returns (bool);

    // Events
    event EnableFallbackHandler(address fallbackHandler);
    event DisableFallbackHandler(address fallbackHandler);
}
```

#### Hooks

Hooks are an OPTIONAL extension of this standard. Smart accounts MAY use hooks to execute custom logic and checks before and/or after the smart accounts performs an execution.

To comply with this OPTIONAL extension, smart accounts MUST implement the entire interface below and they

- MUST call the `onInstall` or `onUninstall` function on the module when enabling or disabling a hook
- MUST pass the sanitized initialisation data to the module when enabling or disabling a hook
- SHOULD store the module address during the enable process and remove it during the disable process
- MUST emit the relevant event for the module type
- MUST enforce authorization control on the relevant enable or disable function for the module type
- SHOULD allow for the relevant enable or disable function for the module type to be called by the account as part of a batch
- MUST call the `preCheck` function before a smart account execution with the execution parameters
- MUST call the `postCheck` function after a smart account execution with the return value of `preCheck`

```solidity
interface IAccountConfig_Hook {
    // HOOKS
    // Functions
    function enableHook(address hook, bytes calldata data) external;
    function disableHook(address hook, bytes calldata data) external;
    function isHookEnabled(address hook) external view returns (bool);

    // Events
    event EnableHook(address hook);
    event DisableHook(address hook);
}
```

#### ERC-1271 Forwarding

The smart account MUST implement the [ERC-1271](./erc-1271.md) interface. The `isValidSignature` function calls MAY be forwarded to validator. If ERC-1271 forwarding is implemented, the validator MUST be called with `isValidSignatureWithSender(address sender, bytes32 hash, bytes signature)`, where the sender is the `msg.sender` of the call to the smart account.

Should the smart account implement any validator selection encoding in the `bytes signature` parameter, the smart account MUST sanitize the parameter, before forwarding it to the validator.

The smart account's ERC-1271 `isValidSignature` function SHOULD return the return value of the validator that the request was forwarded to.

#### Fallback

Smart accounts MAY implement a fallback function that forwards the call to a fallback handler.

If the account has a fallback handler enabled, it:

- MUST use `call` to invoke the fallback handler
- MUST implement authorization control
- MUST utilize [ERC-2771](./erc-2771.md) to add the original `msg.sender` to the `calldata` sent to the fallback handler

#### ERC-165

Smart accounts MUST implement [ERC-165](./erc-165.md) with meta-interfaces. These will be used by wallets or dapps to discover which functionality is supported by the account.

```solidity
function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    if(interfaceID == type(IERC165).interfaceID) return true;
    else if (interfaceID == type(IExecution).interfaceId) return true;
    else if (interfaceID == type(IAccountConfig).interfaceId) return true;
    // Only if Hook extension is supported
    else if (interfaceID == type(IAccountConfig_Hook).interfaceId) return true;
    else return false;
}

```

### Modules

This standard separates modules into the following different types that each has a unique and incremental identifier, which SHOULD be used by accounts, modules and other entities to identify the module type:

- Validation (type id: 1)
- Execution (type id: 2)
- Fallback (type id: 3)

Note: A single module can be of multiple types.

Modules MUST implement the following interface, which is used by smart accounts to enable and disable modules:

```solidity
interface IModule {
    function onInstall(bytes calldata data) external;
    function onUninstall(bytes calldata data) external;
    function isModuleType(uint256 typeID) external view returns(bool);
}
```

Modules MUST revert if `onInstall` or `onUninstall` was unsuccessful.

#### Validators

- Validators MUST implement the `IModule` interface and have module type id: `1`.
- Validators are called during the ERC-4337 validation phase and MUST implement the ERC-4337 `validateUserOp` method.
- Validators MUST validate that the signature is a valid signature of the userOpHash, and SHOULD return SIG_VALIDATION_FAILED (and not revert) on signature mismatch.

```solidity
function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external returns (uint256);
```

Validators MUST also implement the `isValidSignatureWithSender` function. The validator MUST return the ERC-1271 `MAGIC_VALUE` if the signature is valid and MUST NOT modify state.

The parameter `address sender` is the contract that sent the ERC-1271 request to the smart account. The validator MAY utilize this parameter for validation (i.e. EIP-712 domain separators).

```solidity
function isValidSignatureWithSender(address sender, bytes32 hash, bytes calldata signature) external view returns (bytes4);
```

#### Executors

Executors MUST implement the `IModule` interface.

#### Fallback Handlers

Fallback handlers MUST implement the `IModule` interface and have module type id: `3`.

Fallback handlers that implement sensitive functions require authorization control, MUST NOT rely on `msg.sender` for authorization control. Authorization control MUST use ERC-2771 checks to validate, that the `_msgSender() == msg.sender`.

#### Hooks

Hooks MUST implement the `IModule` interface and have module type id: `4`.

Hooks MUST implement the `preCheck` function. After checking the transaction data, `preCheck` MAY return arbitrary data in the `hookData` return value.

```solidity
function preCheck(address sender, address target, uint256 value, bytes calldata data) external returns (bytes memory hookData);
```

Hooks MUST implement the `postCheck` function, which MAY validate the `hookData` to validate transaction context of the `preCheck` function.

```solidity
function postCheck(bytes calldata hookData) external returns (bool success);
```

## Rationale

### Standardization

As mentioned above, there are several reasons for why standardizing smart accounts is very beneficial to the ecosystem. The most important of these are:

- Interoperability for modules to be used across different smart accounts
- Interoperability for smart accounts to be used across different wallet applications and sdks
- Preventing significant vendor lock-in for smart account users

### Minimal approach

Smart accounts are a new concept and we are still learning about the best ways to build them. Therefore, we should not be too opinionated about how they are built. Instead, we should define the most minimal interfaces that allow for interoperability between smart accounts and modules to be used across different account implementations.

Our approach has been twofold:

1. Take learnings from existing smart accounts that have been used in production and from building interoperability layers between them
2. Ensure that the interfaces are as minimal and open to alternative architectures as possible

### Extensions

While we want to be minimal, we also want to allow for innovation and opinionated features. Some of these features might also need to be standardized (for similar reasons as the core interfaces) even if not all smart accounts will implement them. To ensure that this is possible, we have outlined a system for extending the standard with more opinionated features in a backwards-compatible way. Outlining this system is important to ensure that the core interfaces are not overriden by extensions that prevent backwards compatibility and disadvantage accounts that choose not to use these extensions.

### Specifications

#### Multiple execution functions

The ERC-4337 validation phase validates calls to execution functions. Modular validation requires the validation module to know the specific function being validated, especially for Session Key Validators. It needs to know:

1. The function called by Entrypoint on the account.
2. The target address if it is an execution function.
3. Whether it is a `call` or `delegatecall`.
4. Whether it is a single or batched transaction.
5. The function signature used in the interaction with the external contract (e.g., ERC20 transfer).

For a flourishing module ecosystem, compatibility across accounts is crucial. However, if smart accounts implement custom execute functions with different parameters and calldata offsets, it becomes impossible to build reusable modules across accounts.

#### Differentiating module types

Not differentiating between module types could present a security issue when enforcing authorization control. For example, if a smart account treats validators and executors as the same type of module, it could allow a validator to execute arbitrary transactions on behalf of the smart account.

#### Dependence on ERC-4337

This standard has a strict dependency on ERC-4337 for the validation flow. However, it is likely that smart account builders will want to build modular accounts in the future that do not use ERC-4337 but, for example, a native account abstraction implementation on a rollup. Once this starts to happen, the proposed upgrade path for this standard is to move the ERC-4337 dependency into an extension (ie a separate ERC) and to make it optional for smart accounts to implement. If it is required to standardise the validation flow for different account abstraction implementations, then these requirements could also be moved into an extension.

The reason this is not done from the start is that currently, the only modular accounts that are being built are using ERC-4337. Therefore, it makes sense to standardise the interfaces for these accounts first and to move the ERC-4337 dependency into an extension once there is a need for it. This is to maximise learnings about how modular accounts would look like when built on different account abstraction implementations.

## Backwards Compatibility

### Already deployed smart accounts

Smart accounts that have already been deployed will most likely be able to implement this standard. If they are deployed as a proxy, it is possible to upgrade to a new account implementation that is compliant with this standard. If they are deployed as a singleton, it might still be possible to become compliant, for example by adding a compliant adapter as a fallback handler, if this is supported.

## Reference Implementation

Currently [here](./src/MSA.sol)

## Security Considerations

Needs more discussion. Some initial points:

- Modules reverting on uninstall could lead to a modules being uninstallable
- Lack of sufficient fallback authorization control could lead to unauthorized execution even when using only call, such as draining ERC-20s or changing validator configs

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
