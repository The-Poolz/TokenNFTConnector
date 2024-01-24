// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDelayVaultProvider.sol";
import "./interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ConnectorManageable.sol";

contract TokenNFTConnector is ConnectorManageable, ReentrancyGuard {
    ISwapRouter public immutable swapRouter;
    IDelayVaultProvider public immutable delayVaultProvider;
    IERC20 public immutable pairToken;
    uint24 private poolFee;

    constructor(
        IERC20 _token,
        IERC20 _pairToken,
        ISwapRouter _swapRouter,
        IDelayVaultProvider _delayVaultProvider,
        uint24 _poolFee,
        uint256 _projectOwnerFee
    ) ConnectorManageable(_token, _projectOwnerFee) {
        require(
            address(_swapRouter) != address(0) &&
                address(_delayVaultProvider) != address(0) &&
                address(_pairToken) != address(0),
            "TokenNFTConnector: ZERO_ADDRESS"
        );
        swapRouter = _swapRouter;
        delayVaultProvider = _delayVaultProvider;
        pairToken = _pairToken;
        poolFee = _poolFee;
    }

    function createLeaderboard(
        bytes calldata path,
        uint256 amountIn
    ) external whenNotPaused nonReentrant returns (uint256 amountOut) {
        // Decode the first 32 bytes to get the first token address
        IERC20 tokenToSwap = path.length > 31
            ? IERC20(abi.decode(path, (address)))
            : pairToken;
        require(
            tokenToSwap.allowance(msg.sender, address(this)) >= amountIn,
            "TokenNFTCoonector: no allowance"
        );
        tokenToSwap.transferFrom(msg.sender, address(this), amountIn);
        tokenToSwap.approve(address(swapRouter), amountIn);
        // get full path for swap
        bytes memory fullPath = abi.encodePacked(
            path,
            pairToken,
            poolFee,
            token
        );
        amountOut = swapRouter.exactInput(
            ISwapRouter.ExactInputParams({
                path: fullPath,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0
            })
        );

        amountOut = calcMinusFee(amountOut);
        token.approve(address(delayVaultProvider), amountOut);
        uint256[] memory delayParams = new uint256[](1);
        delayParams[0] = amountOut;
        delayVaultProvider.createNewDelayVault(msg.sender, delayParams);
    }
}
