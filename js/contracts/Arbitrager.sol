// SPDX-License-Identifier: Victor Ogbebor
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./defi-interfaces/aave/interfaces/IPool.sol";
import "./defi-interfaces/aave/interfaces/FlashLoanSimpleReceiverBase.sol";

// import uniswap
import "hardhat/console.sol";

contract Arbitrager is FlashLoanSimpleReceiverBase {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event SentProfit(address recipient, uint256 profit);
  event LoanFinished(address token, uint256 amount);

  constructor(IPoolAddressesProvider provider)
    FlashLoanSimpleReceiverBase(provider)
  {}

  // this will activate the flashloan
  function MakeMoney(
    address token,
    uint256 amount,
    address user
  ) external {
    user = address(this); // or msg.sender for now until...
    uint256 balance = IERC20(token).balanceOf(address(this)); // balance before loan happens
    bytes memory data = abi.encode(token, amount, balance);
    IPool(address(POOL)).flashLoanSimple(user, token, amount, data, 0);
  }

  // This will execute the trades and move the money
  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address, // initiator
    bytes memory
  ) external override returns (bool) {
    require(
      amount <= IERC20(asset).balanceOf(address(this)),
      "Invalid Balance for the contract"
    );
    console.log("AmountBorrowed", amount);
    /*
        Steps using uniswap funcs => (Assuming we borrow WETH) 
              
        1) call executeTrades() on Arb Contract
        * Call Uniswap Functions to swap for usdc 
        * Call Sushiswap Functions to swap for weth

        2) call executeSuperTrades() on Arb Contract
        * Call Uniswap Functions to swap for usdc 
        * Call Uniswap Functions to swap for usdt
        * Call Sushiswap Functions to swap for weth
       */

    uint256 amountToPayback = amount.add(premium);
    require(
      IERC20(asset).balanceOf(address(this)) >= amountToPayback,
      "Insufficent funds to payback loan"
    );
    console.log("amount + flashloan fee: ", amountToPayback);
    emit LoanFinished(asset, amountToPayback);

    // Approve Pool contract allowance to payback loan amount
    approve_pool(asset, address(POOL), amountToPayback);

    // transfer remaining balance to address or multisig escrow
    uint256 remained = IERC20(asset).balanceOf(address(this));
    IERC20(asset).transfer(msg.sender, remained);
    emit SentProfit(msg.sender, remained);

    return true;
  }

  /**Internal Func */
  function approve_pool(
    address token,
    address to,
    uint256 amountIn
  ) internal {
    require(IERC20(token).approve(to, amountIn), "approve failed");
  }
}
