// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for interacting with a token-NFT connector contract
interface ITokenNFTConnector {
    /// @notice Creates a leaderboard(new delayVault) for a specified amount using the pancake swap router 
    /// @dev Emits a LeaderboardCreated event upon successful creation
    /// @param amountIn The input amount for the leaderboard creation
    /// @param amountOutMinimum The minimum amount expected as output
    /// @param poolsData Array of swap parameters specifying token addresses and fees
    /// @return amountOut The amount of output tokens
    function createLeaderboard(
        uint256 amountIn,
        uint256 amountOutMinimum,
        SwapParams[] calldata poolsData
    ) external returns (uint256 amountOut);
    
    /// @notice Retrieves bytes from given swap parameters
    /// @param data Array of swap parameters specifying token addresses and fees
    /// @return result The path result in bytes
    function getBytes(
        SwapParams[] calldata data
    ) external returns (bytes memory result);

    struct SwapParams {
        address token;
        uint24 fee;
    }

    /// @notice Emitted when a leaderboard is successfully created
    event LeaderboardCreated(
        address indexed user,
        uint256 amountIn,
        bytes indexed path,
        uint256 amountOut
    );
    /// @notice Emitted when the project owner fee is changed
    event ProjectOwnerFeeChanged(uint256 fee);
    /// @notice Emitted when the project owner fee is withdrawn
    event ProjectOwnerFeeWithdrawn(uint256 amount);

    /// @dev Errors that can be emitted by the contract
    error FeeTooHigh();
    error ZeroBalance();
    error NoZeroAddress();
    error NoAllowance(uint256 amountIn, uint256 allowance);
    error SameTokensInPair();
    error InsufficientOutputAmount();
    error UpdateYourTier(uint256 amountOut);
}
