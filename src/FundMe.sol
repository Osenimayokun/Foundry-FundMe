// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error Fund__NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 5e18;
    // 	889467
    address[] public funders;
    mapping(address => uint256) public amountSentFromFunders;

    address public immutable owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // require(msg.value > 1e18,"Didn't send enough ETH"); // WEI TO ETHER
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough ETH"
        );
        // require(getConversionRate(msg.value) >= minimumUSD,"Didn't send enough ETH");
        funders.push(msg.sender);
        amountSentFromFunders[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Must be the Owner"); // Was ticked out because a modifer will be created
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            amountSentFromFunders[funder] = 0;
        }

        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");

        // // transfer
        // // msg.sender=address
        // // payable(msg.sender)=payable  address
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess=payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        // // call
    }

    modifier onlyOwner() {
        // require(msg.sender == owner, "Must be the Owner");
        if (msg.sender != owner) {
            revert Fund__NotOwner();
        }
        _;
    }

    // When someone sends this contract ETH without calling the fund function

    // receive()
    receive() external payable {
        fund();
    }

    // fallback()
    fallback() external payable {
        fund();
    }
}
