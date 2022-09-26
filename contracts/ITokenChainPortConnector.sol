// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITokenChainPortConnector {
    event TokenChainPortConnectorUpdate(
        address indexed tokenAddress,
        address indexed tokenChainPort
    );

    function tokenChainPorts(address tokenAddress)
        external
        returns (address tokenChainPort);
}
