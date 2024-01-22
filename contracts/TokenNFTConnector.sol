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
        uint256 amountIn,
        bytes[] calldata data
    ) external whenNotPaused returns (uint256 amountOut) {
        require(
            tokenToSwap.allowance(msg.sender, address(this)) >= amountIn,
            "TokenNFTCoonector: no allowance"
        );
        tokenToSwap.transferFrom(msg.sender, address(this), amountIn);
        tokenToSwap.approve(address(swapRouter), amountIn);
        bytes[] memory results = swapRouter.multicall(data);
        amountOut = calcMinusFee(
            abi.decode(results[results.length - 1], (uint256))
        );
        token.approve(address(delayVaultProvider), amountOut);
        uint256[] memory delayParams = new uint256[](1);
        delayParams[0] = amountOut;
        delayVaultProvider.createNewDelayVault(msg.sender, delayParams);
    }
}
