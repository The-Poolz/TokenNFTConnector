// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDelayVaultProvider.sol";
import "./interfaces/ISwapRouter.sol";
import "./ConnectorManageable.sol";

contract TokenNFTConnector is ConnectorManageable {
    ISwapRouter public swapRouter;
    IDelayVaultProvider public delayVaultProvider;
    uint24 poolFee;

    constructor(
        IERC20 _token,
        ISwapRouter _swapRouter,
        IDelayVaultProvider _delayVaultProvider,
        uint24 _poolFee,
        uint256 _projectOwnerFee
    ) ConnectorManageable(_token, _projectOwnerFee) {
        require(
            address(_swapRouter) != address(0),
            "TokenNFTConnector: ZERO_ADDRESS"
        );
        require(
            address(_delayVaultProvider) != address(0),
            "TokenNFTConnector: ZERO_ADDRESS"
        );
        swapRouter = _swapRouter;
        delayVaultProvider = _delayVaultProvider;
        poolFee = _poolFee;
    }

    function createLeaderboard(
        IERC20 tokenToSwap,
        uint256 amountIn
    ) external whenNotPaused returns (uint256 amountOut) {
        require(
            tokenToSwap.allowance(msg.sender, address(this)) >= amountIn,
            "TokenNFTCoonector: no allowance"
        );
        tokenToSwap.transferFrom(msg.sender, address(this), amountIn);
        tokenToSwap.approve(address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(tokenToSwap),
                tokenOut: address(token),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = calcMinusFee(swapRouter.exactInputSingle(params));
        token.approve(address(delayVaultProvider), amountOut);
        uint256[] memory delayParams = new uint256[](1);
        delayParams[0] = amountOut;
        delayVaultProvider.createNewDelayVault(msg.sender, delayParams);
    }
}
