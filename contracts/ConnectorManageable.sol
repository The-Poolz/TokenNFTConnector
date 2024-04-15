// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ITokenNFTConnector.sol";

/// @title Connector Manageable Contract
/// @notice Abstract contract providing management functionalities for a token-NFT connector
abstract contract ConnectorManageable is ITokenNFTConnector, Ownable, Pausable {
    using SafeERC20 for IERC20;

    /// @notice The token used in the connector
    IERC20 public immutable token;
    /// @notice The project owner fee percentage
    uint256 public projectOwnerFee;
    /// @notice The maximum fee percentage allowed
    uint256 public constant MAX_FEE = 3e17; // 30% (0.3 * 1e18)

    /// @notice Initializes the Connector Manageable Contract
    /// @param _token The token contract address
    /// @param _projectOwnerFee The initial project owner fee percentage
    constructor(IERC20 _token, uint256 _projectOwnerFee) Ownable(msg.sender) {
        if (address(_token) == address(0)) revert NoZeroAddress();
        if (_projectOwnerFee > MAX_FEE) revert FeeTooHigh();
        token = _token;
        projectOwnerFee = _projectOwnerFee;
    }

    /// @notice Sets the project owner fee percentage
    /// @param fee The new project owner fee percentage
    function setProjectOwnerFee(uint256 fee) external onlyOwner {
        if (fee > MAX_FEE) revert FeeTooHigh();
        projectOwnerFee = fee;
        emit ProjectOwnerFeeChanged(fee);
    }


    /// @notice Pauses the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Withdraws the project owner fee from the contract
    function withdrawFee() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) revert ZeroBalance();
        token.safeTransfer(owner(), balance);
        emit ProjectOwnerFeeWithdrawn(balance);
    }

    /// @notice Calculates the amount after deducting the project owner fee
    /// @param amount The original amount
    /// @return leftAmount The amount after deducting the project owner fee
    function calcMinusFee(uint256 amount) public view returns (uint256 leftAmount) {
        leftAmount = amount - (amount * projectOwnerFee) / 1e18;
    }
}