// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./OrderStruct.sol";

abstract contract Signature {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    string private constant _NAME = "Aliya Exchange";
    string private constant _VERSION = "1.0";

    bytes32 private _FEE_TYPEHASH;
    bytes32 private _ORDER_TYPEHASH;
    bytes32 private _DOMAIN_SEPARATOR;

    function _initTypehashes() internal {
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

        _ORDER_TYPEHASH = keccak256(
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

        _FEE_TYPEHASH = keccak256("Fee(uint16 rate,address recipient)");

        _DOMAIN_SEPARATOR = _hashDomain(
            eip712DomainTypehash,
            keccak256(bytes(_NAME)),
            keccak256(bytes(_VERSION)),
            address(this)
        );
    }

    function _hashDomain(
        bytes32 eip712DomainTypehash,
        bytes32 nameHash,
        bytes32 versionHash,
        address proxy
    ) private view returns (bytes32) {
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

    function _hashFee(Fee calldata fee) internal view returns (bytes32) {
        return keccak256(abi.encode(_FEE_TYPEHASH, fee.rate, fee.recipient));
    }

    function _packFees(Fee[] calldata fees) internal view returns (bytes32) {
        bytes32[] memory feeHashes = new bytes32[](fees.length);
        for (uint256 i = 0; i < fees.length; i++) {
            feeHashes[i] = _hashFee(fees[i]);
        }
        return keccak256(abi.encodePacked(feeHashes));
    }

    function _hashOrder(
        Order calldata order,
        uint256 nonce
    ) internal view returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        _ORDER_TYPEHASH, 
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

    function _hashToSign(
        bytes32 orderHash
    ) internal view returns (bytes32 hash) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, orderHash)
            );
    }

    // function _hashToSignRoot(
    //     bytes32 root
    // ) internal view returns (bytes32 hash) {
    //     return
    //         keccak256(
    //             abi.encodePacked(
    //                 "\x19\x01",
    //                 _DOMAIN_SEPARATOR,
    //                 keccak256(abi.encode(_ROOT_TYPEHASH, root))
    //             )
    //         );
    // }

    uint256[44] private __gap;
}
