// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITokenChainPort {
    event TokenChainPortUpdate(
        uint256 indexed chainId,
        address indexed tokenAddress
    );

    function tokenChains(uint256 chainId)
        external
        returns (address tokenAddress);
}
