// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDelayVaultProvider.sol";
import "./interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ConnectorManageable.sol";

contract TokenNFTConnector is ConnectorManageable, ReentrancyGuard {
    ISwapRouter public immutable swapRouter;
    IDelayVaultProvider public immutable delayVaultProvider;
    IERC20 public immutable pairToken;

    constructor(
        IERC20 _token,
        IERC20 _pairToken,
        ISwapRouter _swapRouter,
        IDelayVaultProvider _delayVaultProvider,
        uint256 _projectOwnerFee
    ) ConnectorManageable(_token, _projectOwnerFee) {
        require(
            address(_swapRouter) != address(0) &&
                address(_delayVaultProvider) != address(0) &&
                address(_pairToken) != address(0),
            "TokenNFTConnector: ZERO_ADDRESS"
        );
        swapRouter = _swapRouter;
        delayVaultProvider = _delayVaultProvider;
        pairToken = _pairToken;
    }

    function createLeaderboard(
        address[] calldata tokens,
        uint24 poolFee,
        uint256 amountIn
    ) external whenNotPaused nonReentrant returns (uint256 amountOut) {
        IERC20 tokenToSwap = (tokens.length > 0)
            ? IERC20(tokens[0])
            : pairToken;
        require(
            tokenToSwap.allowance(msg.sender, address(this)) >= amountIn,
            "TokenNFTConnector: no allowance"
        );

        tokenToSwap.transferFrom(msg.sender, address(this), amountIn);
        tokenToSwap.approve(address(swapRouter), amountIn);

        amountOut = swapRouter.exactInput(
            ISwapRouter.ExactInputParams({
                path: getBytes(tokens, poolFee),
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0
            })
        );
        amountOut = calcMinusFee(amountOut);

        token.approve(address(delayVaultProvider), amountOut);
        uint256[] memory delayParams = new uint256[](1);
        delayParams[0] = amountOut;
        delayVaultProvider.createNewDelayVault(msg.sender, delayParams);
    }

    function getBytes(
        address[] calldata tokens,
        uint24 poolFee
    ) public view returns (bytes memory result) {
        for (uint256 i; i < tokens.length; ++i) {
            result = concatenateBytes(
                result,
                abi.encodePacked(tokens[i], poolFee)
            );
        }
        // add last path element
        result = concatenateBytes(
            result,
            abi.encodePacked(address(pairToken), poolFee, address(token))
        );
    }

    function concatenateBytes(
        bytes memory _bytes1,
        bytes memory _bytes2
    ) public pure returns (bytes memory result) {
        uint256 length = _bytes1.length;
        uint256 length2 = _bytes2.length;
        result = new bytes(length + length2);
        for (uint256 i = 0; i < length; ++i) {
            result[i] = _bytes1[i];
        }
        for (uint256 i = 0; i < length2; ++i) {
            result[length + i] = _bytes2[i];
        }
    }
}
