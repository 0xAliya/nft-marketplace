// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../contracts/OrderStruct.sol";

contract SignUtils {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    string private constant _NAME = "Aliya Exchange";
    string private constant _VERSION = "1.0";

    bytes32 public FEE_TYPEHASH;
    bytes32 public ORDER_TYPEHASH;
    bytes32 public DOMAIN_SEPARATOR;

    constructor(address contractAddress) {
        _initTypehashes(contractAddress);
    }

    function _initTypehashes(address contractAddress) internal {
        bytes32 eip712DomainTypehash = keccak256(
            bytes.concat(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

        ORDER_TYPEHASH = keccak256(
            bytes.concat(
                "Order(",
                "address trader,",
                "uint8 side,",
                "address collection,",
                "uint256 tokenId,",
                "uint256 amount,",
                "address paymentToken,",
                "uint256 price,",
                "uint256 listingTime,",
                "uint256 expirationTime,",
                "Fee[] fees,",
                "uint256 salt,",
                "uint256 nonce",
                ")",
                "Fee(uint16 rate,address recipient)"
            )
        );

        FEE_TYPEHASH = keccak256("Fee(uint16 rate,address recipient)");

        DOMAIN_SEPARATOR = _hashDomain(
            eip712DomainTypehash,
            keccak256(bytes(_NAME)),
            keccak256(bytes(_VERSION)),
            contractAddress
        );
    }

    function _hashDomain(
        bytes32 eip712DomainTypehash,
        bytes32 nameHash,
        bytes32 versionHash,
        address proxy
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    eip712DomainTypehash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    proxy
                )
            );
    }

    function _hashFee(Fee calldata fee) private view returns (bytes32) {
        return keccak256(abi.encode(FEE_TYPEHASH, fee.rate, fee.recipient));
    }

    function _packFees(Fee[] calldata fees) private view returns (bytes32) {
        bytes32[] memory feeHashes = new bytes32[](fees.length);
        for (uint256 i = 0; i < fees.length; i++) {
            feeHashes[i] = _hashFee(fees[i]);
        }
        return keccak256(abi.encodePacked(feeHashes));
    }

    function hashOrder(
        Order calldata order,
        uint256 nonce
    ) external view returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        ORDER_TYPEHASH,
                        order.trader,
                        order.side,
                        order.collection,
                        order.tokenId,
                        order.amount,
                        order.paymentToken,
                        order.price,
                        order.listingTime,
                        order.expirationTime,
                        _packFees(order.fees),
                        order.salt,
                        nonce
                    )
                )
            );
    }

    function hashToSign(
        bytes32 orderHash
    ) external view returns (bytes32 hash) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash)
            );
    }
}
