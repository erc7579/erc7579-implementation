// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MockRegistry
 * @author zeroknots
 * @notice Mock registry for testing purposes
 */
contract MockRegistry {
    function check(
        address plugin,
        address trustedEntity
    )
        external
        view
        returns (uint256 listedAt)
    {
        return uint256(1234);
    }

    function checkN(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256 attestersLength = attesters.length;
        uint256[] memory attestedAtArray = new uint256[](attestersLength);
        for (uint256 i; i < attestersLength; ++i) {
            attestedAtArray[i] = uint256(1234);
        }
        return attestedAtArray;
    }

    function checkNUnsafe(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256 attestersLength = attesters.length;
        uint256[] memory attestedAtArray = new uint256[](attestersLength);
        for (uint256 i; i < attestersLength; ++i) {
            attestedAtArray[i] = uint256(1234);
        }
        return attestedAtArray;
    }
}
