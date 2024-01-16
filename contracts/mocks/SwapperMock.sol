// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/ISwapRouter.sol";

contract SwapperMock is ISwapRouter {
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut) {
        amountOut = params.amountIn * 2;
    }
}
