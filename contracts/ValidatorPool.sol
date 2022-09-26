// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Validator Pool
 * @author Ape Toshi
 * @notice Initial validators are managed by the DAO.
 * @custom:security-contact admin@apetoshi.com
 */
abstract contract ValidatorPool {
    // ========== Events ==========
    event MinBlocksUpdate(uint256 newMinBlocks);
    event MinSignaturesUpdate(uint256 newMinSignatures);
    event ValidatorsUpdate(address[] newValidators);

    uint256 public minBlocks;
    uint256 public minSignatures;

    // Trusted oracle network
    address[] public validators;

    constructor(
        uint256 _minBlocks,
        uint256 _minSignatures,
        address[] memory _validators
    ) {
        _configMinBlocks(_minBlocks);
        _configMinSignatures(_minSignatures);
        _configValidators(_validators);
    }

    /// @dev Only trusted addresses can be validators.
    function _configValidators(address[] memory newValidators)
        internal
        virtual
    {
        require(newValidators.length >= minSignatures);
        validators = newValidators;
        emit ValidatorsUpdate(newValidators);
    }

    /// @dev For security purposes, should be at least 50%.
    function _configMinSignatures(uint256 newMinSignatures) internal {
        minSignatures = newMinSignatures;
        emit MinSignaturesUpdate(newMinSignatures);
    }

    /// @dev This is a trade-off between safety and UX. Default to 32.
    function _configMinBlocks(uint256 newMinBlocks) internal {
        minBlocks = newMinBlocks;
        emit MinBlocksUpdate((newMinBlocks));
    }

    // ========== Can be called by any address ==========

    /**
     * @dev Verify if a cross-chain token bridge request is valid.
     * @param txnHash The bytes32 hash of the transaction.
     * @param fromChainId The origin EVM chain ID.
     * @param toChainId The destination EVM chain ID.
     * @param fromTokenAddress The address of the token on the home chain.
     * @param toTokenAddress The address of the token on the foreign chain.
     * @param account The address of the account.
     * @param amount The amount of tokens to bridge.
     * @param ascendingValidatorIds Validator Id array in ascending order
     * @param validatorSignatures Array of validator signatures
     */
    function _isValid(
        bytes32 txnHash,
        uint256 fromChainId,
        uint256 toChainId,
        address fromTokenAddress,
        address toTokenAddress,
        address account,
        uint256 amount,
        uint256[] calldata ascendingValidatorIds,
        bytes[] memory validatorSignatures
    ) internal view returns (bool) {
        require(
            _checkAscendingValidatorIds(ascendingValidatorIds),
            "Invalid Validator ID array"
        );
        require(
            validatorSignatures.length >= minSignatures,
            "Not enough signatures"
        );
        require(
            validatorSignatures.length == ascendingValidatorIds.length,
            "Signature and validator arrays have to match"
        );
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                txnHash,
                fromChainId,
                toChainId,
                fromTokenAddress,
                toTokenAddress,
                account,
                amount
            )
        );
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);

        address validator;
        uint256 id;
        for (uint256 i; i < minSignatures; ) {
            id = ascendingValidatorIds[i];
            validator = validators[id];
            if (
                !_verifySigner(
                    ethSignedMessageHash,
                    validatorSignatures[i],
                    validator
                )
            ) {
                return false;
            }

            unchecked {
                i++;
            }
        }
        return true;
    }

    // ========== Helper functions ==========

    /**
     * @notice Signature is produced by signing a keccak256 hash with the following format:
     * "\x19Ethereum Signed Message\n" + len(msg) + msg
     */
    function _getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /// @dev Recover the signer address from `ethSignedMessageHash`.
    function _recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    /// @dev Split a `signature` into `r`, `s` and `v` values.
    function _splitSignature(bytes memory signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "invalid signature length");

        assembly {
            /// @dev First 32 bytes stores the length of the signature

            /// @dev add(sig, 32) = pointer of sig + 32
            /// @dev Effectively, skips first 32 bytes of signature

            /// @dev mload(p) loads next 32 bytes starting at the memory address p into memory

            /// @dev First 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            /// @dev Second 32 bytes
            s := mload(add(signature, 64))
            /// @dev Final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        // Implicitly return (r, s, v)
    }

    /// @dev Verify if `signature` on `ethSignedMessageHash` was signed by `signer`.
    function _verifySigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool) {
        return _recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    /**
     * @dev Checks if array is sorted in ascending order such that
     * every element is unique and not greater than 5 (6th validator).
     */
    function _checkAscendingValidatorIds(
        uint256[] calldata ascendingValidatorIds
    ) internal view returns (bool) {
        uint256 first;
        uint256 second;
        for (uint256 i = 1; i < ascendingValidatorIds.length; ) {
            first = ascendingValidatorIds[i - 1];
            second = ascendingValidatorIds[i];
            /// Array has to be sorted in ascending order, 0 to last one
            if (second <= first || second > (validators.length - 1)) {
                return false;
            }

            unchecked {
                i++;
            }
        }
        return true;
    }
}
