// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapperMock is ISwapRouter {
    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut) {
        require(
            token.balanceOf(address(this)) > calcFee(params.amountIn),
            "SwapperMock: not enough balance"
        );
        amountOut = params.amountIn * 2;
        uint256 fee = calcFee(amountOut);
        // return fee to sender
        token.transfer(msg.sender, fee);
    }

    function calcFee(uint256 amount) public pure returns (uint256 leftAmount) {
        leftAmount = (amount * 1000) / 10000;
    }
}
