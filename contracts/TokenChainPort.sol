// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITokenChainPort.sol";

abstract contract TokenChainPort is ITokenChainPort {
    mapping(uint256 => address) public tokenChains;

    function _configTokenChains(uint256 chainId, address tokenAddress)
        internal
    {
        tokenChains[chainId] = tokenAddress;
        emit TokenChainPortUpdate(chainId, tokenAddress);
    }
}
