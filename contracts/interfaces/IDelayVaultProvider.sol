// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelayVaultProvider {
    /**
     * @dev Creates a new delay vault associated with the specified owner and parameters.
     * @param owner The address of the vault owner.
     * @param params An array of parameters for the new delay vault.
     * @return poolId The unique identifier of the newly created delay vault.
     */
    function createNewDelayVault(
        address owner,
        uint256[] memory params
    ) external returns (uint256 poolId);
}
