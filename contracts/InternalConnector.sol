// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConnectorManageable.sol";

abstract contract InternalConnector is ConnectorManageable {
    using SafeERC20 for IERC20;

    function _checkAllowance(IERC20 token, uint256 amountIn) internal view {
        uint256 allowance = token.allowance(msg.sender, address(this));
        if (allowance < amountIn) revert NoAllowance(amountIn, allowance);
    }

    function _transferInERC20Tokens(
        IERC20 token,
        uint256 amountIn
    ) internal returns (uint256) {
        uint256 amountBeforeSwap = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amountIn);
        return token.balanceOf(address(this)) - amountBeforeSwap;
    }

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
}
