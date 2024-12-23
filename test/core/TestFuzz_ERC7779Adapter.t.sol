// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { MockERC7779 } from "../mocks/MockERC7779.sol";
import "forge-std/Test.sol";

/// @title TestFuzz_ERC7779Adapter
/// @notice Tests the ERC7779Adapter contract
contract TestFuzz_ERC7779Adapter is Test {
    MockERC7779 private mockERC7779;

    function setUp() public {
        mockERC7779 = new MockERC7779();
        //bytes32 erc7779StorageBase =
        // keccak256(abi.encode(uint256(keccak256(bytes("InteroperableDelegatedAccount.ERC.Storage")))
        // - 1)) & ~bytes32(uint256(0xff));
        //console.logBytes32(erc7779StorageBase);
    }

    function test_Fuzz_ERC7779Adapter_AddStorageBases(uint256 amountOfBases) public {
        vm.assume(amountOfBases > 0 && amountOfBases < 100);
        bytes32[] memory expectedStorageBases = new bytes32[](amountOfBases);

        for (uint256 i = 0; i < amountOfBases; i++) {
            bytes32 storageBase = bytes32(uint256(i));
            expectedStorageBases[i] = storageBase;
            mockERC7779.addStorageBase(storageBase);
        }

        bytes32[] memory retrievedStorageBases = mockERC7779.accountStorageBases();
        assertEq(retrievedStorageBases.length, amountOfBases);
        for (uint256 i = 0; i < amountOfBases; i++) {
            assertEq(retrievedStorageBases[i], expectedStorageBases[i]);
        }
    }
}
