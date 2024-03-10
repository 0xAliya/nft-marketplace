// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum Side {
    Buy,
    Sell
}
enum SignatureVersion {
    Single,
    Bulk
}
enum AssetType {
    ERC721,
    ERC1155
}

struct Fee {
    uint16 rate;
    address payable recipient;
}

struct Order {
    // 订单创建者
    address trader;
    // 订单类型
    Side side;
    // 订单集合地址
    address collection;
    // 订单tokenId
    uint256 tokenId;
    // 订单数量
    uint256 amount;
    // 订单支付token
    address paymentToken;
    // 订单价格
    uint256 price;
    // 订单创建时间
    uint256 listingTime;
    // 订单过期时间
    uint256 expirationTime;
    // 订单费用
    Fee[] fees;
    // 订单随机数
    uint256 salt;
}

struct Input {
    Order order;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes extraSignature;
    SignatureVersion signatureVersion;
    uint256 blockNumber;
}

struct Execution {
    Input sell;
    Input buy;
}