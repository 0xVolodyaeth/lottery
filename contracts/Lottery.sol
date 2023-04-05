// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IPrize} from "./interfaces/IPrize.sol";

contract Lottery is Ownable, ReentrancyGuard {
    bool private onGoing;
    IPrize private prize;

    struct Bid {
        address bidder;
        uint160 amount;
        uint blockNumber;
    }

    Bid private highestBid;
    event BidMade(address bidder, uint160 amount);

    error BidTooSmall();
    error LotteryEnded();
    error LotteryIsOnGoing();

    constructor() {}

    function startGame(address _prize) external onlyOwner {
        prize = IPrize(_prize);
        onGoing = true;
    }

    modifier whenOnGoing() {
        require(onGoing, "Lottery: not started");
        _;
    }

    function bid(uint160 _bid) external payable whenOnGoing nonReentrant {
        if (
            block.number > highestBid.blockNumber + 3 &&
            highestBid.blockNumber != 0
        ) {
            revert LotteryEnded();
        }

        if (highestBid.amount > _bid) {
            revert BidTooSmall();
        }

        bool sent;
        // return eth back to the highest bidder
        if (highestBid.bidder != address(0)) {
            (sent, ) = address(this).call{value: highestBid.amount}("");
            require(sent, "Lottery: failed to send");
        }

        // get eth from a new one_
        (sent, ) = msg.sender.call{value: _bid}("");
        require(sent, "Lottery: failed to send");

        highestBid = Bid(msg.sender, _bid, block.number);
        emit BidMade(msg.sender, _bid);
    }

    function end() external onlyOwner {
        Bid memory bid_ = highestBid;

        if (block.number < bid_.blockNumber + 3) {
            revert LotteryIsOnGoing();
        }

        prize.transfer(bid_.bidder);
    }

    function getHighestBid() external view returns (address, uint160, uint256) {
        return (highestBid.bidder, highestBid.amount, highestBid.blockNumber);
    }

    receive() external payable {}
}
