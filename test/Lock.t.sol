// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Lock} from "../contracts/Lock.sol";

contract CounterTest is Test {
    Lock public lock;

    function setUp() public {
        lock = new Lock(block.timestamp + 7 days);
    }
  
}
