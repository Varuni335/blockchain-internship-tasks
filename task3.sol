// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract DeFiLending {
    IERC20 public token;

    uint256 public totalSupplied;
    uint256 public totalBorrowed;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public debts;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function getUtilization() public view returns (uint256) {
        if (totalSupplied == 0) return 0;
        return (totalBorrowed * 1e18) / totalSupplied;
    }

    function getInterestRate() public view returns (uint256) {
        uint256 util = getUtilization();
        return 2e16 + ((util * 5e16) / 1e18); // 2% base, up to 7% dynamic
    }

    function lend(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        deposits[msg.sender] += amount;
        totalSupplied += amount;
    }

    function borrow(uint256 amount) external {
        uint256 rate = getInterestRate();
        uint256 interest = (amount * rate) / 1e18;
        uint256 debtWithInterest = amount + interest;

        require(debtWithInterest <= token.balanceOf(address(this)), "Insufficient liquidity");

        debts[msg.sender] += debtWithInterest;
        totalBorrowed += debtWithInterest;

        token.transfer(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        require(amount <= debts[msg.sender], "Overpayment");

        debts[msg.sender] -= amount;
        totalBorrowed -= amount;
    }

    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Not enough deposited");
        require(token.balanceOf(address(this)) >= amount, "Insufficient pool liquidity");

        deposits[msg.sender] -= amount;
        totalSupplied -= amount;

        token.transfer(msg.sender, amount);
    }
}