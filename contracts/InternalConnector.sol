// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConnectorManageable.sol";
import "./interfaces/IDelayVaultProvider.sol";
import "./interfaces/ISwapRouter.sol";

/// @title Internal Connector Contract
/// @notice Abstract contract providing internal functionalities for token swapping and delay vault management
abstract contract InternalConnector is ConnectorManageable {
    using SafeERC20 for IERC20;

    /// @notice The delay vault provider contract address
    IDelayVaultProvider public immutable delayVaultProvider;
    /// @notice The swap router contract address
    ISwapRouter public immutable swapRouter;


    /// @notice Checks if the caller has allowed the contract to spend the specified amount of tokens
    /// @param token The token to check allowance for
    /// @param amountIn The amount to be spent
    function _checkAllowance(IERC20 token, uint256 amountIn) internal view {
        uint256 allowance = token.allowance(msg.sender, address(this));
        if (allowance < amountIn) revert NoAllowance(amountIn, allowance);
    }

    /// @notice Transfers ERC20 tokens from the caller to the contract
    /// @param token The token to transfer
    /// @param amountIn The amount to transfer
    /// @return The actual amount transferred
    function _transferInERC20Tokens(
        IERC20 token,
        uint256 amountIn
    ) internal returns (uint256) {
        uint256 amountBeforeSwap = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amountIn);
        return token.balanceOf(address(this)) - amountBeforeSwap;
    }

    /// @notice Encodes swap parameters into bytes format
    /// @param data Array of swap parameters specifying token addresses and fees
    /// @param pairToken The paired token for swapping
    /// @param poolFee The fee associated with the token pair
    /// @param token The token to swap
    /// @return result Encoded bytes representing the swap path
    function _getBytes(
        SwapParams[] calldata data,
        IERC20 pairToken,
        uint24 poolFee,
        IERC20 token
    ) internal pure returns (bytes memory result) {
        for (uint256 i; i < data.length; ++i) {
            require(
                data[i].token != address(0),
                "TokenNFTConnector: zero address token in path"
            );
            result = abi.encodePacked(
                result,
                abi.encodePacked(data[i].token, data[i].fee)
            );
        }
        // add last path element
        result = abi.encodePacked(
            result,
            abi.encodePacked(address(pairToken), poolFee, address(token))
        );
    }

    /// @notice Creates a new delay vault and deposits tokens into it
    /// @param amountOut The amount of tokens to deposit into the delay vault
    function _createNewDelayVault(uint256 amountOut) internal {
        // Increase allowance for DelayVaultProvider using SafeERC20's
        // Delay vault only works with POOLX token so no need to reset allowance
        token.safeIncreaseAllowance(address(delayVaultProvider), amountOut);
        uint256[] memory delayParams = new uint256[](1);
        delayParams[0] = amountOut;
        delayVaultProvider.createNewDelayVault(msg.sender, delayParams);
    }

    /// @notice Executes a token swap using the provided swap path
    /// @param path The swap path
    /// @param amountIn The amount of input tokens
    /// @param amountOutMinimum The minimum amount of output tokens expected
    /// @return The amount of output tokens received
    function _swapTokens(
        bytes memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal returns (uint256) {
        return swapRouter.exactInput(
                ISwapRouter.ExactInputParams({
                    path: path,
                    recipient: address(this),
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMinimum
                })
            );
    }
}
