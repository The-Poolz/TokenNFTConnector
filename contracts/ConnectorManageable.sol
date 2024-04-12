// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract ConnectorManageable is Ownable, Pausable {
    using SafeERC20 for IERC20;

    event ProjectOwnerFeeChanged(uint256 fee);
    event ProjectOwnerFeeWithdrawn(uint256 amount);

    error FeeTooHigh();
    error ZeroBalance();
    error NoZeroAddress();

    IERC20 public immutable token;
    uint256 public projectOwnerFee;
    uint256 public constant MAX_FEE = 3e17; // 30% (0.3 * 1e18)

    constructor(IERC20 _token, uint256 _projectOwnerFee) Ownable(msg.sender) {
        if (address(_token) == address(0)) revert NoZeroAddress();
        if (_projectOwnerFee > MAX_FEE) revert FeeTooHigh();
        token = _token;
        projectOwnerFee = _projectOwnerFee;
    }

    function setProjectOwnerFee(uint256 fee) external onlyOwner {
        if (fee > MAX_FEE) revert FeeTooHigh();
        projectOwnerFee = fee;
        emit ProjectOwnerFeeChanged(fee);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawFee() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) revert ZeroBalance();
        token.safeTransfer(owner(), balance);
        emit ProjectOwnerFeeWithdrawn(balance);
    }

    function calcMinusFee(uint256 amount) public view returns (uint256 leftAmount) {
        leftAmount = amount - (amount * projectOwnerFee) / 1e18;
    }
}