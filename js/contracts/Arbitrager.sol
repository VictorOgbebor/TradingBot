// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import "./AaveFlashloanSimpleContract.sol";

// create withdraw function

contract Arbitrager {
  AaveFlashloanSimpleContract aave;

  function MakeMoney(address asset, uint256 amount) external {
    aave.aave_flashloan(asset, amount, address(this));
  }
}
