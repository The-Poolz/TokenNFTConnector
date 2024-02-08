// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ConnectorManageable is Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    IERC20 public token;
    uint256 public projectOwnerFee;
    uint256 public constant MAX_FEE = 1e18; // 100%
    
    function __Manageable_init(IERC20 _token, uint256 _projectOwnerFee) internal onlyInitializing {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();
        require(address(_token) != address(0), "ConnectorManageable: ZERO_ADDRESS");
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
        token.transfer(owner(), balance);
    }

    function calcMinusFee(
        uint256 amount
    ) public view returns (uint256 leftAmount) {
        leftAmount = amount - (amount * projectOwnerFee) / MAX_FEE;
    }

    ///@dev added onlyOwner modifier for `upgradeToAndCall` 
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
