// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDelayVaultProvider.sol";
import "./interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ConnectorManageable.sol";

contract TokenNFTConnector is ConnectorManageable, ReentrancyGuard {
    ISwapRouter public swapRouter;
    IDelayVaultProvider public delayVaultProvider;

    constructor(
        IERC20 _token,
        ISwapRouter _swapRouter,
        IDelayVaultProvider _delayVaultProvider,
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
    }

    function createLeaderboard(
        IERC20 tokenToSwap,
        uint256 amountIn,
        bytes[] calldata data
    ) external whenNotPaused nonReentrant returns (uint256 amountOut) {
        require(
            tokenToSwap.allowance(msg.sender, address(this)) >= amountIn,
            "TokenNFTCoonector: no allowance"
        );
        tokenToSwap.transferFrom(msg.sender, address(this), amountIn);
        tokenToSwap.approve(address(swapRouter), amountIn);
        bytes[] memory results = swapRouter.multicall(data);
        for (uint256 i = 0; i < results.length; ++i) {
            amountOut += abi.decode(results[i], (uint256));
        }
        amountOut = calcMinusFee(amountOut);
        token.approve(address(delayVaultProvider), amountOut);
        uint256[] memory delayParams = new uint256[](1);
        delayParams[0] = amountOut;
        delayVaultProvider.createNewDelayVault(msg.sender, delayParams);
    }
}
