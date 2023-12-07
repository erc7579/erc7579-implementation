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

This proposal outlines the minimally required interfaces and behavior for modular smart accounts and modules to ensure their interoperability.

## Motivation

Contract accounts are gaining adoption with many new accounts being built in a modular fashion. These modular contract accounts (hereafter smart accounts) move functionality into external contracts (modules) in order to increase the speed and potential of innovation, to future-proof themselves and to allow customizability by developers and users. However, currently these smart accounts are built in vastly different ways, creating vendor lock-in and module fragmentation.

To solve these problems, we need to standardize the core interfaces for smart accounts and modules. However, it is highly important that this standardization is done with minimal impact on the implementation logic of the accounts, so that smart account vendors can innovate and compete, while also allowing a flourishing, multi-account-compatible module ecosystem.

The goals of this standard are:

- define the most minimal interfaces for smart accounts and modules that ensure interoperability between accounts
- outline a system for extending this standard with more opinionated features in a backwards-compatible way

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definitions

- **Smart account** - An ERC-4337 compliant smart contract account that has a modular architecture.
- **Module** - A smart contract with self-contained smart account functionality.
  - Validator: A Module that validates ERC-4337 compliant User Operation and ERC-1271.
  - Executor: A Module that can be added to a smart account, that can execute transactions on behalf of the smart account via a callback.
  - Fallback Handler: A Module that can can extend the fallback functionality of a smart account.
- **Entrypoint** - A trusted singleton contract according to ERC-4337 specifications.

### Account Spec

The Modular Smart Account can utilize modules to extend it's capabilities.

#### Execution Methods

Standardizing execute functions and separating them into granular methods, allows ERC-4337 SessionKey validation modules to easily scope, what transaction it is approving.

To comply with this standard, smart accounts MUST implement ALL interfaces. If an account implementation elects to not support any of the execute methods, it MUST revert, in order to avoid unpredictable behavior with fallbacks.

##### execute

This function is intended to be primarily used to be executed within the ERC-4337 execution phase and invoked by the ERC-4337 Entrypoint.

If the account supports this interface:

- Smart account MUST execute a `call` to the provided target with the provided parameters for value and calldata.
- MUST implement authorization control, scoped to allow ERC-4337 Entrypoint.
- MAY implement authorization control, scoped to allow `msg.sender == address(this)`.
- The smart account MUST revert if the call was not successful.

If the account does not support this feature:

- MUST implement the interface
- MUST revert

```solidity
function execute(address target, uint256 value, bytes data) external returns (bytes memory result);
```

###### executeBatch

This function is intended to be primarily used to be executed within the ERC-4337 execution phase and invoked by the ERC-4337 Entrypoint.

Transaction Batching is a commonly requested feature in smart accounts.
If the account supports this interface:

- Smart account MUST iterate over the arrays provided as parameters and execute a `call` for each of the provided `target, values, data` pairs.
- To avoid unexpected behavior, the Smart Account SHALL ensure that the length of the provided arrays are equal.
- MUST implement authorization control, scoped to allow ERC-4337 Entrypoint.
- MAY implement authorization control, scoped to allow `msg.sender == address(this)`.
- Function MUST revert if any of the calls was not successful.

If the account does not support this feature:

- MUST implement the interface
- MUST revert

```solidity
function executeBatch(address[] targets, uint256[] values, bytes[] data) external returns (bytes memory result);
```

##### executeDelegateCall

This function is intended to be primarily used to be executed within the ERC-4337 execution phase and invoked by the ERC-4337 Entrypoint.

If the account supports this interface:

- Smart account MUST execute a `delegatecall` to the provided target with provided calldata.
- MUST implement authorization control, scoped to allow ERC-4337 entrypoint.
- MAY implement authorization control, scoped to allow `msg.sender == address(this)`.
- Function MUST revert if the call was not successful.

If the account does not support this feature:

- MUST implement the interface
- MUST revert

```solidity
function executeDelegateCall(address target, bytes data) external returns (bytes memory result);
```

##### executeFromModule

This function is interned to be used by Executor Modules. It allows enabled modules, to execute transactions on behalf of the smart account.

If the account supports this interface:

- Smart account MUST execute a `call` to the provided target with provided calldata.
- MUST implement authorization control, scoped to only allow enabled modules to execute this function.
- Function MUST revert if the call was not successful.

If the account does not support this feature:

- MUST implement the interface
- MUST revert

```solidity
function executeFromModule(address target, uint256 value, bytes data) external returns (bytes memory result);
```

##### executeDelegateCallFromModule

This function is interned to be used by Executor Modules. It allows enabled modules, to execute transactions on behalf of the smart account.

If the account supports this interface:

- Smart account MUST execute a `delegatecall` to the provided target with provided calldata.
- MUST implement authorization control, scoped to only allow enabled modules to execute this function.
- Function MUST revert if the call was not successful.

If the account does not support this feature:

- MUST implement the interface
- MUST revert

```solidity
function executeDelegateCallFromModule(address target, bytes data) external returns (bytes memory result);
```

##### executeDelegateCallFromModule

This function is interned to be used by Executor Modules. It allows enabled modules, to execute transactions on behalf of the smart account.

If the account supports this interface:

- Smart account MUST execute multiple `call` to the provided targets with provided calldatas.
- MUST implement authorization control, scoped to only allow enabled modules to execute this function.
- Function MUST revert if any of the calls was not successful.

If the account does not support this feature:

- MUST implement the interface
- MUST revert

```solidity
function executeBatchFromModule(address[] targets, uint256[] values, bytes[] data) external returns (bytes memory result);
```

#### Account configurations

When enabling modules to the smart account, the smart account implementation MUST different between the module types. Not doing so, can create a security issue.

##### Configure Validators

Validator Modules can be added and removed from the smart account. Additional values needed for enabling/disabling MAY be passed as `abi.encoded` values via the `bytes calldata data` parameter.

When enabling a Validator, the Smart account MUST call the `IValidator(validator).enable()` function
When disabling a Validator, the Smart account MUST call the `IValidator(validator).disable()` function
Smart account SHOULD implement default validators, or ensure that at least one validator remains enabled on the account, to prevent a user from losing control over his/her smart account.
Authorization control is REQUIRED for `enableValidator()` and `disableValidator()`.

```solidity
function enableValidator(address validator, bytes calldata data) external;
function disableValidator(address validator, bytes calldata data) external;
function isValidatorEnabled(address validator) external view returns (bool);
```

When enabling a Validator, the Smart account MUST emit `EnableValidatorModule(address)`
When disabling a Validator, the Smart account MUST emit `DisableValidatorModule(address)`

```solidity
// Events
event EnableValidatorModule(address validator);
event DisableValidatorModule(address validator);
```

##### Configure Executors

Executor Modules can be added and removed from the smart account. Additional values needed for enabling/disabling MAY be passed as `abi.encoded` values via the `bytes calldata data` parameter.

When enabling a Executor, the Smart account MUST call the `IExecutor(executor).enable()` function
When disabling a Executor, the Smart account MUST call the `IExecutor(executor).disable()` function
Authorization control is REQUIRED for `enableValidator()` and `disableValidator()`.

```solidity
function enableExecutor(address executor, bytes calldata data) external;
function disableExecutor(address executor, bytes calldata data) external;
function isExecutorEnabled(address executor) external view returns (bool);
```

When enabling an Executor, the Smart account MUST emit `EnableExecutorModule(address)`
When disabling an Executor , the Smart account MUST emit `DisableExecutorModule(address)`

```solidity
// Events
event EnableExecutorModule(address executor);
event DisableExecutorModule(address executor);
```

##### Configure Fallback Handler

Fallback Handlers can be added and removed from the smart account.

When enabling a Fallback Handler, the Smart account MUST call the `IFallbackHandler(_fallback).enable()` function
When disabling a Fallback Handler, the Smart account MUST call the `IFallbackHandler(_fallback).disable()` function
Authorization control is REQUIRED for `enableFallback()` and `disableFallback()`.

```solidity
function enableFallback(address fallbackHandler, bytes calldata data) external;
function disableFallback(address fallbackHandler, bytes calldata data) external;
function isFallbackEnabled(address fallbackHandler) external view returns (bool);
```

When enabling a Fallback Handler, the Smart account MUST emit `EnableFallbackHandler(address)`
When disabling a Fallback Handler , the Smart account MUST emit `DisableFallbackHandler(address)`

```solidity
// Events
event EnableFallbackHandler(address fallbackHandler);
event DisableFallbackHandler(address fallbackHandler);

```

#### ERC-4337 Validation Phase and Validation Module Selection

This Standard does NOT dictate how “Validation Module” selection is implemented. (userOp.signature, modes, userOp.nonce, other factors).
Should a smart account encode validation selection mechanisms in ERC-4337 userOps fields (i.e. userOp.signature), the smart account is REQUIRED to sanitize the affected userOp value BEFORE invoking the validation module.

The smart account's `validateUserOp` function SHOULD return the return value of the Validation Module.

#### ERC-1271 Forwarding

The smart account MUST implement the ERC-1271 interface. The ERC-1271 call MAY be forwarded to Validation Modules. If ERC-1271 forwarding is implemented,
the Validation Module MUST be called with `isValidSignature(address sender, bytes32 hash, bytes signature)`, where the sender is the msg.sender of the ERC-1271 and hash is the `bytes32 hash` for the original ERC-1271 call.

Should the smart account implement any validator selection encoding in the `bytes signature` parameter, the smart account MUST sanitize the parameter, before forwarding it to the Validation Module.

Should a smart account encode validation selection mechanisms in ERC-1271 `bytes signature`, the smart account is REQUIRED to sanitize the `bytes signature` value BEFORE invoking the validation module.

The smart account's ERC-1271 `isValidSignature` function SHOULD return the return value of the Validation Module that the request was forwarded to.

#### Fallback

Smart accounts MAY implement a fallback function that that MAY forward the call to a Fallback Handler. If implemented and enabled, the Fallback Handler MUST be called with `call`.

If the account has a fallback handler enabled:

- Smart accounts MUST use `call` to invoke the Fallback Handler
- Smart account MUST utilize ERC-2771 to add the original `msg.sender` to the `calldata` sent to the Fallback Handler

```solidity
// Example on how to implement ERC-2771 in fallback
// Code inspired by (Gnosis) Safe 1.4
fallback() external {
    bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
    assembly {
        let handler := sload(slot)
        if iszero(handler) { return(0, 0) }

        let calldataPtr := allocate(calldatasize())
        calldatacopy(calldataPtr, 0, calldatasize())

        // The msg.sender address is shifted to the left by 12 bytes to remove the padding
        // Then the address without padding is stored right after the calldata
        let senderPtr := allocate(20)
        mstore(senderPtr, shl(96, caller()))

        // Add 20 bytes for the address appended add the end
        let success := call(gas(), handler, 0, calldataPtr, add(calldatasize(), 20), 0, 0)

        let returnDataPtr := allocate(returndatasize())
        returndatacopy(returnDataPtr, 0, returndatasize())
        }
}

```

### Module Spec

This standard is separating modules into the following different types:

- Validation
- Execution
- Fallback

Note: It is possible that module developers build business logic, that requires a module to be multiple types at the same time.

#### Validation Modules

The smart account MUST call enable/disable functions while adding and removing modules to the smart account.
Validation Modules MUST implement enable and disable functions.

```solidity
function enable(bytes calldata data) external;
function disable(bytes calldata data) external;
```

Validation Modules are called during the ERC-4337 validation phase and MUST implement the ERC-4337 `validateUserOp` method.
Validation Modules MUST validate that the signature is a valid signature of the userOpHash, and SHOULD return SIG_VALIDATION_FAILED (and not revert) on signature mismatch.

```solidity
function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external returns (uint256);
```

Validation Modules MUST implement a `isValidSignature`. The function can call arbitrary methods to validate a given signature, which could be context dependent (e.g. time based or state based), EOA dependent (e.g. signers authorization level within smart wallet), signature scheme Dependent (e.g. ECDSA, multisig, BLS), etc.

The parameter `address sender` is the contract that sent the ERC-1271 request to the smart account. The Validation Module MAY utilize this parameter for validation (i.e. EIP-712 domain separators)
Validation Module MUST validate that the signature is a valid signature of the `bytes32 hash`.
Validation Module MUST return ERC-1271 `MAGIC_VALUE` if the signature is valid.

```solidity
function isValidSignature(address sender, bytes32 hash, bytes calldata signature) external view returns (bytes4);
```

#### Executor Modules

The smart account MUST call enable/disable functions while adding and removing modules to the smart account.
Executor Modules MUST implement enable and disable functions.

```solidity
function enable(bytes calldata data) external;
function disable(bytes calldata data) external;
```

#### Fallback Handlers

The smart account MUST call enable/disable functions while adding and removing modules to the smart account.
Fallback Handlers MUST implement enable and disable functions.

```solidity
function enable(bytes calldata data) external;
function disable(bytes calldata data) external;
```

Fallback Handlers that implement sensitive functions require authorization control, MUST NOT rely on `msg.sender` for authorization control.
Authorization Control MUST use ERC-2771 checks to validate, that the `_msgSender() == msg.sender`.

### Extensions

Guidelines for extensions:

tbd

## Rationale

### standardization

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

## Backwards Compatibility

No backward compatibility issues found.

## Reference Implementation

Open question: add interface or add entire msa implementation (in assets)

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
