// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITokenChainPortConnector.sol";
import "./TokenChainPort.sol";

abstract contract TokenChainPortConnector is ITokenChainPortConnector {
    mapping(address => address) public tokenChainPorts;

    function _configTokenChainPorts(
        address tokenAddress,
        address tokenChainPort
    ) internal {
        tokenChainPorts[tokenAddress] = tokenChainPort;
        emit TokenChainPortConnectorUpdate(tokenAddress, tokenChainPort);
    }
}
