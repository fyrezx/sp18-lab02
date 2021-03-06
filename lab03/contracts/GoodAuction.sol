pragma solidity 0.4.19;

import "./AuctionInterface.sol";

/** @title GoodAuction */
contract GoodAuction is AuctionInterface {

	/* New data structure, keeps track of refunds owed */
	mapping(address => uint) refunds;


	/* 	Bid function, now shifted to pull paradigm
		Must return true on successful send and/or bid, bidder
		reassignment. Must return false on failure and 
		allow people to retrieve their funds  */
	function bid() payable external returns(bool) {
		// YOUR CODE HERE
		//Failure
		if (msg.value > highestBid) {
			refunds[highestBidder] += highestBid;
			highestBidder = msg.sender;
			highestBid = msg.value;
			return true;
		}
		refunds[msg.sender] += msg.value;
		return false;
		
	}

	/*  Implement withdraw function to complete new 
	    pull paradigm. Returns true on successful 
	    return of owed funds and false on failure
	    or no funds owed.  */
	function withdrawRefund() external returns(bool) {
		// YOUR CODE HERE
		uint refund = refunds[msg.sender];
		if (refunds[msg.sender] == 0) {
			return false;
		} else {
			refunds[msg.sender] = 0;
			msg.sender.transfer(refund);
			return true;
		} 
	}

	/*  Allow users to check the amount they are owed
		before calling withdrawRefund(). Function returns
		amount owed.  */
	function getMyBalance() constant external returns(uint) {
		return refunds[msg.sender];
	}


	/* 	Consider implementing this modifier
		and applying it to the reduceBid function 
		you fill in below. */
	modifier canReduce() {
		//Only for truffle
		if (msg.sender != highestBidder) {
			return;
		}
		//for real code on the mainnet
		// require(msg.sender == highestBidder);
		_;
	}


	/*  Rewrite reduceBid from BadAuction to fix
		the security vulnerabilities. Should allow the
		current highest bidder only to reduce their bid amount */
	function reduceBid() external canReduce() {
		if (highestBid > 0) {
			highestBid = highestBid - 1;
			require(highestBidder.send(1));
		} 
			
		

	}


	/* 	Remember this fallback function
		gets invoked if somebody calls a
		function that does not exist in this
		contract. But we're good people so we don't
		want to profit on people's mistakes.
		How do we send people their money back?  */

	function () payable {
		// YOUR CODE HERE
		revert();
	}

}
