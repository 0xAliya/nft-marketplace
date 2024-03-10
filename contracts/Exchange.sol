// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./Executor.sol";
import "./OrderStruct.sol";

contract AliyaNFTExchange is
    Executor,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    mapping(address => uint256) public nonces;
    mapping(bytes32 => bool) public cancelledOrFilled;

    event Cancelled(bytes32 hash);
    event Executed(
        address indexed maker,
        address indexed taker,
        Order sell,
        bytes32 sellHash,
        Order buy,
        bytes32 buyHash
    );
    event NonceIncremented(address indexed trader, uint256 newNonce);

    // constructor() {
    //     _disableInitializers();
    // }

    function initialize() external initializer {
        __Ownable_init(_msgSender());
        _initTypehashes();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function execute(
        Input calldata buyer,
        Input calldata seller
    ) external payable {
        _execute(buyer, seller);
    }

    function getNonces(address trader) external view returns (uint256) {
        return nonces[trader];
    }

    function _execute(
        Input calldata buyer,
        Input calldata seller
    ) public payable nonReentrant {
        _verifyExecuteInputs(buyer, seller);

        bytes32 buyerOrderHash = _hashOrder(
            buyer.order,
            nonces[buyer.order.trader]
        );

        bytes32 sellerOrderHash = _hashOrder(
            seller.order,
            nonces[seller.order.trader]
        );

        _verifyCancelledOrFilled(cancelledOrFilled, buyerOrderHash);
        _verifyCancelledOrFilled(cancelledOrFilled, sellerOrderHash);

        require(
            _verifySignature(
                buyerOrderHash,
                buyer.order.trader,
                buyer.v,
                buyer.r,
                buyer.s,
                buyer.signatureVersion
            ),
            "Validation: buyer order signature is invalid"
        );

        require(
            _verifySignature(
                sellerOrderHash,
                seller.order.trader,
                seller.v,
                seller.r,
                seller.s,
                seller.signatureVersion
            ),
            "Validation: seller order signature is invalid"
        );

        _transferFunds(
            buyer.order.trader,
            seller.order.trader,
            buyer.order.paymentToken,
            buyer.order.price
        );

        _transferNFT(
            buyer.order.collection,
            seller.order.trader,
            buyer.order.trader,
            buyer.order.tokenId,
            buyer.order.amount,
            AssetType.ERC721
        );

        emit Executed(
            seller.order.trader,
            buyer.order.trader,
            seller.order,
            sellerOrderHash,
            buyer.order,
            buyerOrderHash
        );
    }

    function cancelOrder(Order calldata order) public {
        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.trader, "Not sent by trader");

        bytes32 hash = _hashOrder(order, nonces[order.trader]);

        require(!cancelledOrFilled[hash], "Order cancelled or filled");

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFilled[hash] = true;
        emit Cancelled(hash);
    }

    function incrementNonce() external {
        emit NonceIncremented(msg.sender, nonces[msg.sender]++);
    }

    uint256[44] private __gap;
}
