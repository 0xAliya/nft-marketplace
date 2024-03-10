// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Validation.sol";
import "./OrderStruct.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract Executor is Validation {
    function _transferFunds(
        address buyer,
        address seller,
        address paymentToken,
        uint256 price
    ) internal {
        if (paymentToken == address(0)) {
            require(msg.value >= price, "Incorrect value");
            (bool success, ) = seller.call{value: price}("");
            require(success, "Transfer failed");
            if (msg.value > price) {
                (bool successRefund, ) = buyer.call{value: msg.value - price}(
                    ""
                );
                require(successRefund, "Refund failed");
            }
        } else {
            require(
                IERC20(paymentToken).transferFrom(buyer, seller, price),
                "Transfer failed"
            );
        }
    }

    function _transferNFT(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        AssetType assetType
    ) internal {
        require(_exists(collection), "Collection does not exist");

        if (assetType == AssetType.ERC1155) {
            IERC1155(collection).safeTransferFrom(
                from,
                to,
                tokenId,
                amount,
                ""
            );
        } else if (assetType == AssetType.ERC721) {
            IERC721(collection).transferFrom(from, to, tokenId);
        }
    }

    function _exists(address what) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(what)
        }
        return size > 0;
    }

    uint256[44] private __gap;
}
