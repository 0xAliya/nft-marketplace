// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {AliyaNFTExchange} from "../contracts/Exchange.sol";
import {SignUtils} from "./SignUtils.sol";
import {Side, Fee, Input, Order, SignatureVersion} from "../contracts/OrderStruct.sol";

import "./Mocks/MockNFT.sol";

import {Upgrades} from "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract ExchangeTest is Test {
    AliyaNFTExchange exchange;
    MockNFT nft;
    SignUtils signUtils;

    address public owner = makeAddr("owner");
    address public buyer = vm.addr(0x2);
    address public seller = vm.addr(0x1);

    function setUp() public {
        vm.startPrank(owner);
        address proxy = Upgrades.deployUUPSProxy(
            "Exchange.sol:AliyaNFTExchange",
            abi.encodeWithSelector(AliyaNFTExchange.initialize.selector)
        );

        exchange = AliyaNFTExchange(address(proxy));
        vm.stopPrank();

        nft = new MockNFT();

        signUtils = new SignUtils(address(exchange));

        vm.deal(address(this), 10 ether);
        vm.deal(buyer, 100 ether);
        vm.deal(seller, 100 ether);
    }

    function test_initialize() public {
        assertEq(exchange.owner(), address(owner));
    }

    function test_execute() public {
        vm.startPrank(seller);
        nft.mint(seller, 1);
        nft.approve(address(exchange), 1);
        vm.stopPrank();

        Order memory sellOrder = Order(
            seller,
            Side.Sell,
            address(nft),
            1,
            1,
            address(0),
            1 ether,
            block.timestamp,
            block.timestamp + 1 days,
            new Fee[](0),
            0
        );

        bytes32 sellerOrderTypedDataHash = signUtils.hashOrder(
            sellOrder,
            exchange.getNonces(seller)
        );

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
            0x1,
            signUtils.hashToSign(sellerOrderTypedDataHash)
        );

        Order memory buyOreder = Order(
            buyer,
            Side.Buy,
            address(nft),
            1,
            1,
            address(0),
            1 ether,
            block.timestamp,
            block.timestamp + 1 days,
            new Fee[](0),
            0
        );

        bytes32 buyerOrderTypedDataHash = signUtils.hashOrder(
            buyOreder,
            exchange.getNonces(buyer)
        );
        console.logBytes32(buyerOrderTypedDataHash);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(
            0x2,
            signUtils.hashToSign(buyerOrderTypedDataHash)
        );
        vm.startPrank(buyer);
        exchange.execute{value: 1 ether}(
            Input(
                buyOreder,
                v2,
                r2,
                s2,
                new bytes(0),
                SignatureVersion.Single,
                block.number
            ),
            Input(
                sellOrder,
                v1,
                r1,
                s1,
                new bytes(0),
                SignatureVersion.Single,
                block.number
            )
        );

        assertEq(seller.balance, 101 ether);
        assertEq(nft.ownerOf(1), buyer);
    }
}
