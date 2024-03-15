// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IDelayVaultProvider.sol";

contract DelayMock is IDelayVaultProvider {
    mapping(address => uint256) public ownerToAmount;
    mapping(uint8 => uint256) public typeToLimit;
    uint256 public counter;
    uint256 public constant typesCount = 3;

    constructor() {
        typeToLimit[0] = 200 ether;
        typeToLimit[1] = 10000 ether;
        typeToLimit[2] = type(uint256).max;
    }

    function createNewDelayVault(
        address owner,
        uint256[] memory params
    ) external returns (uint256 poolId) {
        require(params.length == 1, "DelayMock: wrong params length");
        ownerToAmount[owner] += params[0];
        poolId = counter++;
    }

    function getTotalAmount(
        address user
    ) external view override returns (uint256) {
        return ownerToAmount[user];
    }

    function theTypeOf(uint256 amount) public view returns (uint8 theType) {
        for (uint8 i = 0; i < typesCount; ++i) {
            if (amount <= typeToLimit[i]) {
                theType = i;
                break;
            }
        }
    }
}
