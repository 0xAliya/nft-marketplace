// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Signature.sol";
import "./OrderStruct.sol";
abstract contract Validation is Signature {
    function _verifyCancelledOrFilled(
        mapping(bytes32 => bool) storage cancelledOrFilled,
        bytes32 orderHash
    ) internal view {
        require(
            !cancelledOrFilled[orderHash],
            "Validation: order is cancelled or filled"
        );
    }

    function _verifyExecuteInputs(
        Input calldata buyer,
        Input calldata seller
    ) internal view {
        _verifyOrderParameters(buyer.order);
        _verifyOrderParameters(seller.order);
        require(
            buyer.order.trader != seller.order.trader,
            "Validation: buyer and seller are the same"
        );
        require(
            buyer.order.side == Side.Buy,
            "Validation: buyer order is not buy"
        );
        require(
            seller.order.side == Side.Sell,
            "Validation: seller order is not sell"
        );
        require(
            buyer.order.paymentToken == seller.order.paymentToken,
            "Validation: paymentToken is different"
        );
        require(
            buyer.order.collection == seller.order.collection,
            "Validation: collection is different"
        );
        require(
            buyer.order.tokenId == seller.order.tokenId,
            "Validation: tokenId is different"
        );
        require(
            buyer.order.amount == seller.order.amount,
            "Validation: amount is different"
        );
        require(
            buyer.order.price >= seller.order.price,
            "Validation: buyer price < seller price"
        );
        require(
            buyer.order.expirationTime > block.timestamp,
            "Validation: buyer order is expired"
        );
        require(
            seller.order.expirationTime > block.timestamp,
            "Validation: seller order is expired"
        );
    }

    function _verifyOrderParameters(Order memory order) internal pure {
        require(
            order.trader != address(0),
            "Validation: trader is zero address"
        );
        require(
            order.collection != address(0),
            "Validation: collection is zero address"
        );
        require(
            order.listingTime < order.expirationTime,
            "Validation: listingTime >= expirationTime"
        );
        require(order.price > 0, "Validation: price is zero");
        require(order.amount > 0, "Validation: amount is zero");
    }

    function _verifySignature(
        bytes32 orderHash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        SignatureVersion signatureVersion
    ) internal view returns (bool) {
        bytes32 hashToSign = _hashToSign(orderHash);
        return _verify(signer, hashToSign, v, r, s);
    }

    function _verify(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        require(v == 27 || v == 28, "Invalid v parameter");
        address recoveredSigner = ecrecover(digest, v, r, s);
        if (recoveredSigner == address(0)) {
            return false;
        } else {
            return signer == recoveredSigner;
        }
    }
    
    uint256[44] private __gap;
}
