// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISwapRouter.sol";

contract SwapperMock is ISwapRouter {
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut) {}
}
