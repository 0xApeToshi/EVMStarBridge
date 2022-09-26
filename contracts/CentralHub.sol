// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DAOSafety.sol";
import "./TokenChainPortConnector.sol";
import "./ITokenChainPort.sol";
import "./ValidatorPool.sol";

contract CentralHub is
    DAOSafety,
    ReentrancyGuard,
    TokenChainPortConnector,
    ValidatorPool
{
    // ========== Events ==========
    event ForeignDeliveryRequest(
        address indexed account,
        address indexed homeTokenAddress,
        uint256 amount,
        uint256 indexed toChainId
    );
    event ForeignDeliveryFulfill(
        address indexed account,
        address indexed homeTokenAddress,
        uint256 amount,
        uint256 indexed fromChainId
    );
    // ========== Public variables ==========
    mapping(bytes32 => bool) public txnHashes;

    // ========== Private/internal variables ==========
    uint256 internal immutable HOME_CHAIN_ID;

    constructor(
        uint256 _HOME_CHAIN_ID,
        address _DAO_MULTISIG,
        uint256 _minBlocks,
        uint256 _minSignatures,
        address[] memory _validators
    )
        DAOSafety(_DAO_MULTISIG)
        ValidatorPool(_minBlocks, _minSignatures, _validators)
    {
        HOME_CHAIN_ID = _HOME_CHAIN_ID;
    }

    // ========== External functions ==========

    // tokenAddress on this chain
    // ERC20 needs to be approved first!
    function exportToken(
        address account,
        address homeTokenAddress,
        uint256 amount,
        uint256 toChainId
    ) external whenNotPaused nonReentrant {
        // token
        address foreignTokenAddress = ITokenChainPort(
            tokenChainPorts[homeTokenAddress]
        ).tokenChains(toChainId);

        require(foreignTokenAddress != address(0), "Token not portable");
        require(
            IERC20(homeTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Balance too low or not approved"
        );
        emit ForeignDeliveryRequest(
            account,
            homeTokenAddress,
            amount,
            toChainId
        );
    }

    // tokenAddress on this chain
    function importToken(
        bytes32 txnHash,
        uint256 fromChainId,
        address account,
        address homeTokenAddress,
        uint256 amount,
        uint256[] calldata ascendingValidatorIds,
        bytes[] memory validatorSignatures
    ) external whenNotPaused nonReentrant {
        require(!txnHashes[txnHash], "Already imported");
        txnHashes[txnHash] = true;
        // token address on bridged chain
        address foreignTokenAddress = ITokenChainPort(
            tokenChainPorts[homeTokenAddress]
        ).tokenChains(fromChainId);

        require(foreignTokenAddress != address(0), "Token not portable");

        bool valid = _isValid(
            txnHash,
            fromChainId,
            HOME_CHAIN_ID,
            foreignTokenAddress,
            homeTokenAddress,
            account,
            amount,
            ascendingValidatorIds,
            validatorSignatures
        );
        require(valid, "Validation failed");

        // Fulfill request
        require(
            IERC20(homeTokenAddress).transfer(account, amount),
            "Unable to fulfill request" // This should never happen
        );
        emit ForeignDeliveryFulfill(
            account,
            homeTokenAddress,
            amount,
            fromChainId
        );
    }

    // ========== Only DAO ==========

    function configTokenChainPorts(address tokenAddress, address tokenChainPort)
        external
        onlyDAO
    {
        _configTokenChainPorts(tokenAddress, tokenChainPort);
    }

    /// @dev Only trusted addresses can be validators.
    function configValidators(address[] memory newValidators) external onlyDAO {
        _configValidators(newValidators);
    }

    /// @dev For security purposes, has to be at least 3/6. Default to 4/6.
    function configMinSignatures(uint256 newMinSignatures) external onlyDAO {
        _configMinSignatures(newMinSignatures);
    }

    /// @dev This is a trade-off between safety and UX. Default to 32.
    function configMinBlocks(uint256 newMinBlocks) external onlyDAO {
        _configMinBlocks(newMinBlocks);
    }
}
