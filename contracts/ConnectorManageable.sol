// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract ConnectorManageable is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public projectOwnerFee;
    uint256 public constant MAX_FEE = 1e18; // 100%

    constructor(IERC20 _token, uint256 _projectOwnerFee) Ownable(msg.sender) {
        require(address(_token) != address(0),"ConnectorManageable: zero address token");
        require(_projectOwnerFee < MAX_FEE, "ConnectorManageable: fee is too high");
        token = _token;
        projectOwnerFee = _projectOwnerFee;
    }

    function setProjectOwnerFee(uint256 fee) external onlyOwner {
        require(fee < MAX_FEE, "ConnectorManageable: invalid fee");
        projectOwnerFee = fee;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawFee() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "ConnectorManageable: balance is zero");
        token.safeTransfer(owner(), balance);
    }

    function calcMinusFee(
        uint256 amount
    ) public view returns (uint256 leftAmount) {
        leftAmount = amount - (amount * projectOwnerFee) / MAX_FEE;
    }
}
