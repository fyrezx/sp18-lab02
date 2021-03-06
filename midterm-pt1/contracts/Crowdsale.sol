pragma solidity ^0.4.15;

import './Queue.sol';
import './Token.sol';

/**
 * @title Crowdsale
 * @dev Contract that deploys `Token.sol`
 * Is timelocked, manages buyer queue, updates balances on `Token.sol`
 */

contract Crowdsale {
	// YOUR CODE HERE

	// The contract must keep track of how many tokens have been sold
	uint tokensSold;
	uint startTime;
	uint endTime;
	uint initialTokenAmount;
	uint tokenPerWei;

	bool hasOwnerSetup;

	// The contract must forward all funds to the owner after sale is over
	address public owner;
	mapping (address => bool) public blacklist;
	Token public token;
	Queue public queue;
	
	modifier ownerOnly() {
		//'IF' used instead of 'REQUIRE' because of truffle
		if (msg.sender != owner) {
			return;
		}
		_;
	}
	// The contract must only sell to/refund buyers between start-time and end-time
	modifier buyTime() {
		//'IF' used instead of 'REQUIRE' because of truffle
		if (now < startTime || now > endTime) {
			return;
		}
		_;
	}

	modifier ownerHasNotSetup() {
		if (hasOwnerSetup == true) {
			return;
		}
		_;
	}

	//Enforce a black/white-list of addresses that are/aren't able to participate in the crowdsale
	modifier notBlackList() {
		if (blacklist[msg.sender] == true) {
			return;
		}
		_;
	}

	// Events:
	// Fired on token purchase
	// Fired on token refund
	event TokensPurchased(address purchaserAddress, uint purchasedAmount);
	event TokensRefunded(address refundeeAddress, uint refundedAmount);

	// Owner:
	// Must be set on deployment
	// Must be able to time-cap the sale
	// Must be able to specify an initial amount of tokens to create
	// Must be able to specify the amount of tokens 1 wei is worth
	
	function Crowdsale() public {
		owner = msg.sender;
		// startTime = _startTime;
		// endTime = _endTime;
		// initialTokenAmount = _initialTokenAmount;
		// tokenPerWei = _tokenPerWei;
		tokensSold = 0;
		// uint _startTime, uint _endTime, uint _initialTokenAmount, uint _tokenPerWei, uint _timeLimit

		// 	Must deploy Token.sol 
		//  check out ../migrations/2_deploy_contracts.js (commented part)
		// tokenAddress = _tokenAddress;
		
	}

	function setCrowdsaleDetails(uint _startTime, uint _endTime, uint _initialTokenAmount, uint _tokenPerWei, uint _timeLimit) public ownerOnly() ownerHasNotSetup() returns (bool success)  {
		hasOwnerSetup = true;
		startTime = _startTime;
		endTime = _endTime;
		initialTokenAmount = _initialTokenAmount;
		tokenPerWei = _tokenPerWei;
		token = new Token();
		bool tokenSetupSuccess = token.setTokenSupply(_initialTokenAmount);
		queue = new Queue();
		bool queueSetupSuccess = queue.setTimeLimit(_timeLimit);
		return (tokenSetupSuccess && queueSetupSuccess);
		
	}

	// Must keep track of start-time
	function checkStartTime() view public ownerOnly() returns(uint) {
		return startTime;
	}

	// Must keep track of end-time/time remaining since start-time
	function checkEndTime() view public ownerOnly() returns(uint) {
		return endTime;
	}

	function checkRemainingTime() constant public ownerOnly() returns(uint) {
		return (now-startTime); 
	}
	
	// Must be able to mint new tokens
	// This amount would be added to totalSupply in Token.sol
	function mintToken(uint mintAmount) public ownerOnly() returns(bool success) {
		return token.addToken(mintAmount);
	}
	
	// Must be able to burn tokens not sold yet
	// This amount would be subtracted from totalSupply in Token.sol
	function burnToken(uint burnAmount) public ownerOnly() returns(bool success) {
		return token.subtractToken(burnAmount);
	}

	// Must be able to receive funds from contract after the sale is over
	function sendContractFunds() public ownerOnly() returns (uint fundsReturned) {
		require (now > endTime);
		uint balanceReturned = this.balance;
		owner.transfer(this.balance);
		return balanceReturned;
	}

	// Buyers:
	// Must be able to buy tokens directly from the contract and as long as the sale has not ended, if they are first in the queue and there is someone waiting line behind them
	// This would change their balance in Token.sol
	// This would change the number of tokens sold
	function buyTokens(uint amount) public buyTime() notBlackList() returns (bool success) {
		//need to figure out queue interaction here
		if (msg.sender == queue.getFirst() && queue.qsize() > 1 && queue.qsize() > q.checkPlace()) { // ADDED new condition to ensure one person behind
			tokensSold += amount;
			token.addToBalance(msg.sender, amount);
			TokensPurchased(msg.sender, amount);
			return true;
		}
		return false;
	}	
	
	// Must be able to refund their tokens as long as the sale has not ended. Their place in the queue does not matter
	// This would change their balance in Token.sol
	// This would change the number of tokens sold
	
	function refundTokens(uint amount) public buyTime() returns (bool success) {
		tokensSold -= amount;
		token.removeFromBalance(msg.sender, amount);
		TokensRefunded(msg.sender, amount);
		return true;
	}

	// Add to blacklist
	function addToBlacklist(address blacklistAddress) public ownerOnly() returns (bool success) {
		blacklist[blacklistAddress] = true;
		return blacklist[blacklistAddress];
	}

	function() public payable {
		revert();
	}
}
