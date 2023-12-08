---
title: Minimal Modular Smart Accounts # 44 characters or less
description: <Description is one full (short) sentence> # Todo
author: #Todo
discussions-to: <tbd>
status: Draft
type: Standards Track
category: ERC
created: 2023-12-06
requires: ERC-165, ERC-1271, ERC-2771, ERC-4337
---

## Abstract

<!-- Todo -->

This proposal outlines the minimally required interfaces and behavior for modular smart accounts and modules to ensure their interoperability.

## Motivation

Contract accounts are gaining adoption with many new accounts being built in a modular fashion. These modular contract accounts (hereafter smart accounts) move functionality into external contracts (modules) in order to increase the speed and potential of innovation, to future-proof themselves and to allow customizability by developers and users. However, currently these smart accounts are built in vastly different ways, creating vendor lock-in and module fragmentation.

To solve these problems, we need to standardize the core interfaces for smart accounts and modules. However, it is highly important that this standardization is done with minimal impact on the implementation logic of the accounts, so that smart account vendors can innovate and compete, while also allowing a flourishing, multi-account-compatible module ecosystem.

The goals of this standard are:

- define the most minimal interfaces for smart accounts and modules that ensure interoperability between accounts

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definitions

- **Smart account** - An ERC-4337 compliant smart contract account that has a modular architecture.
- **Module** - A smart contract with self-contained smart account functionality.
  - Validator: A module used during the ERC-4337 validation flow to determine if a `UserOperation` is valid.
  - Executor: A module that can execute transactions on behalf of the smart account via a callback.
  - Fallback Handler: A module that can extend the fallback functionality of a smart account.
- **Entrypoint** - A trusted singleton contract according to ERC-4337 specifications.

### Account

#### Validation

This Standard does not dictate how “Validation Module” selection is implemented. However, should a smart account encode validation selection mechanisms in ERC-4337 `UserOperation` fields (i.e. `userOp.signature`), the smart account MUST sanitize the affected userOp values before invoking the validation module.

The smart account's `validateUserOp` function SHOULD return the return value of the Validation Module.

#### Execution Behavior

To comply with this standard, smart accounts MUST implement the entire interface below. If an account implementation elects to not support any of the execution methods, it MUST revert, in order to avoid unpredictable behavior with fallbacks.

```solidity
interface IExecution{
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
- MUST implement authorization control. For execute functions with `fromModule` in their name, this MUST be scoped to only allow enabled modules to call the function. For all other execute functions, this MUST be scoped to allow the ERC-4337 Entrypoint to call the function and MAY be scoped to allow `msg.sender == address(this)`.
- MUST revert if the call was not successful.

#### Account configurations

To comply with this standard, smart accounts MUST implement the entire interface below. If an account implementation elects to not support any of the execution methods, it MUST revert, in order to avoid unpredictable behavior with fallbacks.

When enabling or disabling a module on a smart account, it

- MUST call the `enable` or `disable` function on the module
- MUST pass the initialisation data to the module
- SHOULD store the module address during the enable process and remove it during the disable process
- MUST emit the relevant event for the module type
- MUST enforce authorization control on the relevant enable or disable function for the module type
- SHOULD allow for the relevant enable or disable function for the module type to be called by the account as part of a batch

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

#### ERC-1271 Forwarding

The smart account MUST implement the ERC-1271 interface. The `isValidSignature` function calls MAY be forwarded to validator. If ERC-1271 forwarding is implemented, the validator MUST be called with `isValidSignature(address sender, bytes32 hash, bytes signature)`, where the sender is the `msg.sender` of the call to the smart account.

Should the smart account implement any validator selection encoding in the `bytes signature` parameter, the smart account MUST sanitize the parameter, before forwarding it to the Validation Module.

The smart account's ERC-1271 `isValidSignature` function SHOULD return the return value of the Validation Module that the request was forwarded to.

#### Fallback

Smart accounts MAY implement a fallback function that forwards the call to a Fallback Handler.

If the account has a fallback handler enabled, it:

- MUST use `call` to invoke the Fallback Handler
- MUST utilize [ERC-2771](./erc-2771.md) to add the original `msg.sender` to the `calldata` sent to the Fallback Handler

### Modules

This standard separates modules into the following different types that each has a unique and incremental identifier, which SHOULD be used by accounts, modules and other entities to identify the module type:

- Validation (ID: 1)
- Execution (ID: 2)
- Fallback (ID: 3)

Note: A single module can be of multiple types.

Modules MUST implement the following interface, which is used by smart accounts to enable and disable modules:

```solidity
interface IModule {
    function enable(bytes calldata data) external;
    function disable(bytes calldata data) external;
    function isModuleType(uint256 typeID) external view returns(bool);
}
```

#### Validators

Validators MUST implement the `IModule` interface.
Validators are called during the ERC-4337 validation phase and MUST implement the ERC-4337 `validateUserOp` method.
Validators MUST validate that the signature is a valid signature of the userOpHash, and SHOULD return SIG_VALIDATION_FAILED (and not revert) on signature mismatch.

```solidity
function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external returns (uint256);
```

Validators MUST implement the `isValidSignature` function. The function can call arbitrary methods to validate a given signature, which could be context dependent (e.g. time based or state based), EOA dependent (e.g. signers authorization level within smart wallet), signature scheme Dependent (e.g. ECDSA, multisig, BLS), etc.

The parameter `address sender` is the contract that sent the ERC-1271 request to the smart account. The Validation Module MAY utilize this parameter for validation (i.e. EIP-712 domain separators)
Validation Module MUST return ERC-1271 `MAGIC_VALUE` if the signature is valid. (Note: validators wont be able to use `this.isValidSignature.selector` since the interface is different to the ERC-1271 interface)

```solidity
function isValidSignature(address sender, bytes32 hash, bytes calldata signature) external view returns (bytes4);
```

#### Executors

Executors MUST implement the `IModule` interface.

#### Fallback Handlers

Fallback Handlers MUST implement the `IModule` interface.
Fallback Handlers that implement sensitive functions require authorization control, MUST NOT rely on `msg.sender` for authorization control.
Authorization Control MUST use ERC-2771 checks to validate, that the `_msgSender() == msg.sender`.

#### Hooks

Hook Modules are an OPTIONAL extension of this standard. Smart accounts MAY use Hooks to execute custom logic and checks before and/or after the smart accounts performs an execution.

To comply with this OPTIONAL extension, smart accounts MUST implement the entire interface below.

- MUST call the `enable` or `disable` function on the module
- MUST pass the initialisation data to the module
- SHOULD store the module address during the enable process and remove it during the disable process
- MUST emit the relevant event for the module type
- MUST enforce authorization control on the relevant enable or disable function for the module type
- SHOULD allow for the relevant enable or disable function for the module type to be called by the account as part of a batch
- MUST call the `preCheck` before a smart account execution with the execution parameters
- MUST call the `postCheck` after a smart account execution with the return value of `preCheck`

```solidity
interface IAccountConfig_Hook {
    function enableHook(address hook, bytes calldata data) external;
    function disableHook(address hook, bytes calldata data) external;
    function isHookEnabled(address hook) external view returns (bool);
}
```

#### Hook Modules

Hooks MUST implement the `IModule` interface.

Hook Modules are represented by ModuleType: `4`.

Hooks MUST implement the `preCheck` function. After checking the transaction data, `preCheck` MAY return arbitrary data in the `hookData` return value.

```solidity
function preCheck(address sender, address target, uint256 value, bytes calldata data) external returns (bytes memory hookData);
```

Hooks MUST implement the `postCheck` function, which MAY validate the `hookData` to validate transaction context of the `preCheck` function.

```solidity
function postCheck(bytes calldata hookData) external returns (bool success);
}
```

### ERC-165

Smart accounts MUST implement ERC-165 with meta-interfaces. These will be very helpful for wallets or dapps to discover which functionality is supported by the account.

```solidity
function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    if(interfaceID == type(IERC165),interfaceID) return true;
    else if (interfaceID == type(IExecution).interfaceId) return true;
    else if (interfaceID == type(IAccountConfig).interfaceId) return true;
    // Only if Hook extension is supported
    else if (interfaceID == type(IAccountConfig_Hook).interfaceId) return true;
    else return false;
}

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

Not differentiating between module types could present a security issue when enforcing authorization control. For example, if a smart account has a validator module enabled, and the validator module is also an executor, the executor could call back into the smart account and perform unauthorized actions.

## Backwards Compatibility

No backward compatibility issues found.

## Reference Implementation

Currently [here](./src/MSA.sol)

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
