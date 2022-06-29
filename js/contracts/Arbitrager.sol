// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
// https://medium.com/coinmonks/flashloan-with-aave-v3-9f94868aeff4
import "./AaveFlashloanSimpleContract.sol";

// create withdraw function
contract Arbitrager {
  AaveFlashloanSimpleContract aave;

  function MakeMoney(address asset, uint256 amount) external {
    aave.aave_flashloan(asset, amount, address(this));
  }
}
