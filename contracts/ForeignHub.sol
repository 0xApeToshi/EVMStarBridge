// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DAOSafety.sol";
import "./ValidatorPool.sol";

import "./IERC20Delivery.sol";

contract ForeignHub is DAOSafety, ReentrancyGuard, ValidatorPool {
    // ========== Events ==========
    event HomeDeliveryRequest(
        address indexed account,
        address indexed foreignTokenAddress,
        uint256 indexed amount
    );
    event HomeDeliveryFulfill(
        address indexed account,
        address indexed foreignTokenAddress,
        uint256 indexed amount
    );

    // ========== Public variables ==========
    mapping(bytes32 => bool) public txnHashes;

    // foreignTokenAddress => homeTokenAddress
    mapping(address => address) public homeTokenAddresses;

    // ========== Private/internal variables ==========
    uint256 internal immutable HOME_CHAIN_ID;
    uint256 internal immutable FOREIGN_CHAIN_ID;

    constructor(
        uint256 _HOME_CHAIN_ID,
        uint256 _FOREIGN_CHAIN_ID,
        address _DAO_MULTISIG,
        uint256 _minBlocks,
        uint256 _minSignatures,
        address[] memory _validators
    )
        DAOSafety(_DAO_MULTISIG)
        ValidatorPool(_minBlocks, _minSignatures, _validators)
    {
        HOME_CHAIN_ID = _HOME_CHAIN_ID;
        FOREIGN_CHAIN_ID = _FOREIGN_CHAIN_ID;
    }

    // ========== External functions ==========

    /**
     * @param account Recipient address
     * @param foreignTokenAddress Address on this chain
     * @param amount Amount of tokens
     */
    function exportToken(
        address account,
        address foreignTokenAddress,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        address homeTokenAddress = homeTokenAddresses[foreignTokenAddress];
        require(homeTokenAddress != address(0), "Token not portable");

        require(
            IERC20Delivery(foreignTokenAddress).burn(msg.sender, amount),
            "Unable to fulfill request"
        );
        emit HomeDeliveryRequest(account, foreignTokenAddress, amount);
    }

    // tokenAddress on this chain
    function importToken(
        bytes32 txnHash,
        address account,
        address foreignTokenAddress,
        uint256 amount,
        uint256[] calldata ascendingValidatorIds,
        bytes[] memory validatorSignatures
    ) external whenNotPaused nonReentrant {
        require(!txnHashes[txnHash], "Already imported");
        txnHashes[txnHash] = true;
        // token address on bridged chain

        address homeTokenAddress = homeTokenAddresses[foreignTokenAddress];
        require(homeTokenAddress != address(0), "Token not portable");

        bool valid = _isValid(
            txnHash,
            HOME_CHAIN_ID,
            FOREIGN_CHAIN_ID,
            homeTokenAddress,
            foreignTokenAddress,
            account,
            amount,
            ascendingValidatorIds,
            validatorSignatures
        );
        require(valid, "Validation failed");

        // Fulfill request
        require(
            IERC20Delivery(foreignTokenAddress).mint(account, amount),
            "Unable to fulfill request"
        );
        emit HomeDeliveryFulfill(account, foreignTokenAddress, amount);
    }

    // ========== Only DAO ==========

    function configHomeTokenAddress(
        address foreignTokenAddress,
        address homeTokenAddress
    ) external onlyDAO {
        homeTokenAddresses[foreignTokenAddress] = homeTokenAddress;
    }

    // ========== Only DAO ==========

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
