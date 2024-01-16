// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDelayVaultProvider.sol";
import "./interfaces/ISwapRouter.sol";

contract TokenNFTConnector {
    ISwapRouter public swapRouter;
    IDelayVaultProvider public delayVaultProvider;
    IERC20 public token;
    uint24 public poolFee;

    constructor(
        IERC20 _token,
        ISwapRouter _swapRouter,
        IDelayVaultProvider _delayVaultProvider,
        uint24 _poolFee
    ) {
        require(
            _swapRouter != ISwapRouter(0),
            "TokenNFTConnector: ZERO_ADDRESS"
        );
        require(_token != IERC20(0), "TokenNFTConnector: ZERO_ADDRESS");
        require(
            _delayVaultProvider != IDelayVaultProvider(0),
            "TokenNFTConnector: ZERO_ADDRESS"
        );
        token = _token;
        swapRouter = _swapRouter;
        delayVaultProvider = _delayVaultProvider;
        poolFee = _poolFee;
    }

    function createLeaderboard(
        IERC20 tokenToSwap,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        require(
            tokenToSwap.allowance(msg.sender, address(swapRouter)) >= amountIn,
            "TokenNFTCoonector: no allowance"
        );
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
        amountOut = swapRouter.exactInputSingle(params);
        token.approve(address(delayVaultProvider), amountOut);
        delayVaultProvider.createNewDelayVault(msg.sender, [amountOut]);
    }
}
