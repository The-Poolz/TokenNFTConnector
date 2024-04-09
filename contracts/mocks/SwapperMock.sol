// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapperMock is ISwapRouter {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public projectOwnerFee;

    constructor(address _token, uint256 _projectOwnerFee) {
        token = IERC20(_token);
        projectOwnerFee = _projectOwnerFee;
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
        token.safeTransfer(msg.sender, fee);
    }

    function calcFee(uint256 amount) public view returns (uint256 fee) {
        fee = (amount * projectOwnerFee) / 1e18;
    }
}
