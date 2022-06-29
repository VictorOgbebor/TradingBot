// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.6;
import "./uniswap/interfaces/v2/IUniswapV2Router.sol";
import "./uniswap/interfaces/v2/IUniswapV2Router02.sol";
import "./uniswap/interfaces/v2/IERC20.sol";

contract SwapOnUniswapV2 {
  IUniswapV2Router public RouterA; // uniswap
  IUniswapV2Router public RouterB; // sushiswap
  address public owner;

  constructor(address _RouterA, address _RouterB) public {
    RouterA = IUniswapV2Router(_RouterA); // Sushiswap
    RouterB = IUniswapV2Router(_RouterB); // Uniswap
    owner = msg.sender;
  }

  event SwapFinished(address token, uint256 amount);

  function executeTrade(
    bool _startOnExchangeA,
    address _token0,
    address _token1,
    uint256 _flashAmount
  ) external view {
    uint256 balanceBefore = IERC20(_token0).balanceOf(address(this));

    bytes memory data = abi.encode(
      _startOnExchangeA,
      _token0,
      _token1,
      _flashAmount,
      balanceBefore
    );
  }

// multihop
  function executeSuperTrade() external {}


// internal funcs
  function _swapOnExchangeA(
    address[] memory _path,
    uint256 _amountIn,
    uint256 _amountOut
  ) internal {
    require(
      IERC20(_path[0]).approve(address(RouterA), _amountIn),
      "ExchangeA approval failed."
    );

    RouterA.swapExactTokensForTokens(
      _amountIn,
      _amountOut,
      _path,
      address(this),
      (block.timestamp + 1200)
    );
  }

  function _swapOnExchangeB(
    address[] memory _path,
    uint256 _amountIn,
    uint256 _amountOut
  ) internal {
    require(
      IERC20(_path[0]).approve(address(RouterB), _amountIn),
      "ExchangeB approval failed."
    );

    RouterB.swapExactTokensForTokens(
      _amountIn,
      _amountOut,
      _path,
      address(this),
      (block.timestamp + 1200)
    );
  }

  // flashswap
}
