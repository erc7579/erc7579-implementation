---
title: Minimal Modular Smart Accounts # 44 characters or less
description: <Description is one full (short) sentence> # Todo
author: #Todo
discussions-to: <tbd>
status: Draft
type: Standards Track
category: ERC
created: 2023-12-06
requires: <EIP number(s)> # Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field.
---

## Abstract

This proposal outlines the minimally required interfaces and behaviour for modular smart accounts and modules to ensure their interoperability.

## Motivation

Contract accounts are gaining adoption with many new accounts being built in a modular fashion. These modular contract accounts (hereafter smart accounts) move functionality into external contracts (modules) in order to increase the speed and potential of innovation, to future-proof themselves and to allow customizability by developers and users. However, currently these smart accounts are built in vastly different ways, creating vendor lock-in and module fragmentation.

To solve these problems, we need to standardize the core interfaces for smart accounts and modules. However, it is highly important that this standardisation is done with minimal impact on the implementation logic of the accounts, so that smart account vendors can innovate and compete, while also allowing a flourishing, multi-account-compatible module ecosystem.

The goals of this standard are:

- define the most minimal interfaces for smart accounts and modules that ensure interoperability between accounts
- outline a system for extending this standard with more opinionated features in a backwards-compatible way

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definitions

- **Smart account** - An ERC-4337 compliant smart contract account that has a modular architecture.
- **Module** - A smart contract with self-contained smart account functionality.

### Execution functions

MUST implement:

- `function execute(address target, uint256 value, bytes data) external returns (bytes memory result);`
- `function executeDelegateCall(address target, bytes data) external returns (bytes memory result);`
- `function executeBatch(address[] targets, uint256[] values, bytes[] data) external returns (bytes memory result);`
- `function executeFromModule(address target, uint256 value, bytes data) external returns (bytes memory result);`
- `function executeDelegateCallFromModule(address target, bytes data) external returns (bytes memory result);`
- `function executeBatchFromModule(address[] targets, uint256[] values, bytes[] data) external returns (bytes memory result);`

If functionality should not be supported, account MUST revert "Unsupported"!

### Account configurations

MUST implement:

- `function initializeAccount(bytes calldata data) external;`
- `function enableValidator(address validator, bytes calldata data) external;`
- `function disableValidator(address validator, bytes calldata data) external;`
- `function isValidatorEnabled(address validator) external view returns (bool);`
- `function enableExecutor(address executor, bytes calldata data) external;`
- `function disableExecutor(address executor, bytes calldata data) external;`
- `function isExecutorEnabled(address executor) external view returns (bool);`
- `function enableFallback(address fallbackHandler, bytes calldata data) external;`
- `function disableFallback(address fallbackHandler, bytes calldata data) external;`
- `function isFallbackEnabled(address fallbackHandler) external view returns (bool);`

Different module types MUST be stored in different places.

question: should account have view function to get all enabled modules or functions for each module type?

### Module interfaces

Validators MUST implement:

- `function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external returns (uint256);`
- `function isValidSignature(bytes32 hash, bytes calldata data) external view returns (bytes4);`

Executors MUST implement:

Nothing.

### Validation

Standard does NOT dictate “Validation Module” selection. (userOp.signature, modes, userOp.nonce, other factors)

However, account MUST clean up any userOp field if it is encoded with additional data. (Question: is this also required if nonce is used?)

### ERC-1271

tbd

### Fallback

Consolidating implementations to use the ERC-2771 msg.sender in calldata might be a good way to get authorization control without adding a lot of gas overhead.

### Extensions

Guidelines for extensions:

tbd

## Rationale

### Standardisation

As mentioned above, there are several reasons for why standardising smart accounts is very beneficial to the ecosystem. The most important of these are:

- Interoperability for modules to be used across different smart accounts
- Interoperability for smart accounts to be used across different wallet applications and sdks
- Preventing significant vendor lock-in for smart account users

### Minimal approach

Smart accounts are a new concept and we are still learning about the best ways to build them. Therefore, we should not be too opinionated about how they are built. Instead, we should define the most minimal interfaces that allow for interoperability between smart accounts and modules to be used across different account implementations.

Our approach has been twofold:

1. Take learnings from existing smart accounts that have been used in production and from building interoperability layers between them
2. Ensure that the interfaces are as minimal and open to alternative architectures as possible

### Extensions

While we want to be minimal, we also want to allow for innovation and opinionated features. Some of these features might also need to be standardised (for similar reasons as the core interfaces) even if not all smart accounts will implement them. To ensure that this is possible, we have outlined a system for extending the standard with more opinionated features in a backwards-compatible way. Outlining this system is important to ensure that the core interfaces are not overriden by extensions that prevent backwards compatibility and disadvantage accounts that choose not to use these extensions.

## Backwards Compatibility

No backward compatibility issues found.

## Reference Implementation

Open question: add interface or add entire msa implementation (in assets)

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
