// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ConnectorManageable is Ownable, Pausable {
    uint256 public projectOwnerFee;
    IERC20 public immutable token;

    constructor(IERC20 _token, uint256 _projectOwnerFee) {
        require(
            address(_token) != address(0),
            "ConnectorManageable: token is zero address"
        );
        token = _token;
        projectOwnerFee = _projectOwnerFee;
    }

    function setProjectOwnerFee(uint24 fee) external onlyOwner {
        require(fee < 10000, "ConnectorManageable: invalid fee");
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
        token.transfer(owner(), balance);
    }

    function calcMinusFee(
        uint256 amount
    ) public view returns (uint256 leftAmount) {
        leftAmount = amount - (amount * projectOwnerFee) / 10000;
    }
}
