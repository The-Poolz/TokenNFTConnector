// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@poolzfinance/poolz-helper-v2/contracts/Nameable.sol";
import "./InternalConnector.sol";

contract TokenNFTConnector is InternalConnector, ReentrancyGuard, Nameable {
    using SafeERC20 for IERC20;

    IERC20 public immutable pairToken;
    uint24 private immutable poolFee; // last pair fee

    constructor(
        IERC20 _token,
        IERC20 _pairToken,
        ISwapRouter _swapRouter,
        IDelayVaultProvider _delayVaultProvider,
        uint24 _poolFee,
        uint256 _projectOwnerFee
    )
        ConnectorManageable(_token, _projectOwnerFee)
        Nameable("TokenNFTConnector", "1.2.0")
    {
        if (address(_token) == address(0)) revert NoZeroAddress();
        if (address(_pairToken) == address(0)) revert NoZeroAddress();
        if (address(_swapRouter) == address(0)) revert NoZeroAddress();
        if (token == _pairToken) revert SameTokensInPair();
        swapRouter = _swapRouter;
        delayVaultProvider = _delayVaultProvider;
        pairToken = _pairToken;
        poolFee = _poolFee;
    }

    function createLeaderboard(
        uint256 amountIn,
        uint256 amountOutMinimum,
        SwapParams[] calldata poolsData
    ) external override whenNotPaused nonReentrant returns (uint256 amountOut) {
        IERC20 tokenToSwap = (poolsData.length > 0)
            ? IERC20(poolsData[0].token)
            : pairToken;

        _checkAllowance(tokenToSwap, amountIn);
        uint256 receivedAmount = _transferInERC20Tokens(tokenToSwap, amountIn);
    
        // Reset allowance to zero before increasing to use USDT
        tokenToSwap.forceApprove(address(swapRouter), 0);
        // Increase allowance using SafeERC20's safeIncreaseAllowance
        tokenToSwap.safeIncreaseAllowance(address(swapRouter), receivedAmount);
        bytes memory path = getBytes(poolsData);
        amountOut = _swapTokens(path, receivedAmount, amountOutMinimum);
        amountOut = calcMinusFee(amountOut);
        if (amountOut < amountOutMinimum) revert InsufficientOutputAmount();
        if (checkIncreaseTier(msg.sender, amountOut)) revert UpdateYourTier(amountOut);

        _createNewDelayVault(amountOut);
        emit LeaderboardCreated(msg.sender, amountIn, path, amountOut);
    }

    function getBytes(
        SwapParams[] calldata data
    ) public override view returns (bytes memory result) {
        return _getBytes(data, pairToken, poolFee, token);
    }

    function checkIncreaseTier(address user, uint256 additionalAmount) public view returns (bool) {
        uint256 userAmount = delayVaultProvider.getTotalAmount(user);
        return delayVaultProvider.theTypeOf(userAmount + additionalAmount) > delayVaultProvider.theTypeOf(userAmount);
    }
}
