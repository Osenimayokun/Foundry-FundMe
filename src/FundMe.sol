// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error Fund__NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 5e18;
    // 	889467
    address[] private s_funders;
    mapping(address => uint256) private s_amountSentFromFunders;

    address private immutable owner;
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
        s_funders.push(msg.sender);
        s_amountSentFromFunders[msg.sender] = msg.value;
    }

    function cheapWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_amountSentFromFunders[funder] = 0;
        }

        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Must be the Owner"); // Was ticked out because a modifer will be created
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_amountSentFromFunders[funder] = 0;
        }

        s_funders = new address[](0);
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

    // View / Pure Functions

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_amountSentFromFunders[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
