// SPDX-License-Identifier: Victor Ogbebor
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./defi-interfaces/aave/interfaces/IPool.sol";
import "./defi-interfaces/aave/interfaces/FlashLoanSimpleReceiverBase.sol";
import "hardhat/console.sol";

contract AaveFlashloanSimpleContract is FlashLoanSimpleReceiverBase {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event SentProfit(address recipient, uint256 profit);
  event LoanFinished(address token, uint256 amount);

  constructor(IPoolAddressesProvider provider)
    FlashLoanSimpleReceiverBase(provider)
  {}

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
        Steps (Assuming we borrow WETH)       
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

    // Approve Pool contract allowancr to payback loan amount
    approvePool(asset, address(POOL), amountToPayback);

    // transfer remaining balance to address or multisig escrow
    uint256 remained = IERC20(asset).balanceOf(address(this));
    IERC20(asset).transfer(msg.sender, remained);
    emit SentProfit(msg.sender, remained);

    return true;
  }

  /**Internal Func */
  function approvePool(
    address token,
    address to,
    uint256 amountIn
  ) internal {
    require(IERC20(token).approve(to, amountIn), "approve failed");
  }

  // uniswap funcs

  // this will activate the flashloan
  function aave_flashloan(
    address token,
    uint256 amount,
    address user
  ) external {
    user = address(this); // or msg.sender for now until...
    IPool(address(POOL)).flashLoanSimple(user, token, amount, "0x", 0);
  }
}
