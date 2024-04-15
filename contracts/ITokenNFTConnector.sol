// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenNFTConnector {
    function createLeaderboard(
        uint256 amountIn,
        uint256 amountOutMinimum,
        SwapParams[] calldata poolsData
    ) external returns (uint256 amountOut);
    
    function getBytes(
        SwapParams[] calldata data
    ) external returns (bytes memory result);

    struct SwapParams {
        address token;
        uint24 fee;
    }

    event LeaderboardCreated(
        address indexed user,
        uint256 amountIn,
        bytes indexed path,
        uint256 amountOut
    );
    event ProjectOwnerFeeChanged(uint256 fee);
    event ProjectOwnerFeeWithdrawn(uint256 amount);

    error FeeTooHigh();
    error ZeroBalance();
    error NoZeroAddress();
    error NoAllowance(uint256 amountIn, uint256 allowance);
    error SameTokensInPair();
    error InsufficientOutputAmount();
    error UpdateYourTier(uint256 amountOut);
}
