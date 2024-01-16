// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IDelayVaultProvider.sol";

contract DelayMock is IDelayVaultProvider {
    mapping(address => uint256) public ownerToAmount;
    uint256 public counter;

    function createNewDelayVault(
        address owner,
        uint256[] memory params
    ) external returns (uint256 poolId) {
        require(params.length == 1, "DelayMock: wrong params length");
        ownerToAmount[owner] = params[0];
        poolId = counter++;
    }
}
