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

    /**
     * @dev Returns the total amount of tokens locked in the delay vault.
     * @param user The address of the delay vault owner.
     * @return The total number of tokens locked in the delay storage, with the migration amount.
     */
    function getTotalAmount(address user) external view returns (uint256);

    /**
     * @dev Returns the type of tier for the delay vault.
     * @param amount The amount of tokens locked in the delay vault.
     * @return The tier level of the delay vault.
     */
    function theTypeOf(uint256 amount) external view returns (uint8);
}
