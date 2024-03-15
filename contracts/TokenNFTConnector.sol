// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@poolzfinance/poolz-helper-v2/contracts/Nameable.sol";
import "./interfaces/IDelayVaultProvider.sol";
import "./interfaces/ISwapRouter.sol";
import "./ConnectorManageable.sol";

contract TokenNFTConnector is ConnectorManageable, ReentrancyGuard, Nameable {
    ISwapRouter public swapRouter;
    IDelayVaultProvider public delayVaultProvider;
    IERC20 public pairToken;
    uint24 private poolFee; // last pair fee

    struct SwapParams {
        address token;
        uint24 fee;
    }

    constructor(
        IERC20 _token,
        IERC20 _pairToken,
        ISwapRouter _swapRouter,
        IDelayVaultProvider _delayVaultProvider,
        uint24 _poolFee,
        uint256 _projectOwnerFee
    )
        ConnectorManageable(_token, _projectOwnerFee)
        Nameable("TokenNFTConnector", "1.2.0")
    {
        require(
            address(_swapRouter) != address(0) &&
                address(_delayVaultProvider) != address(0) &&
                address(_pairToken) != address(0),
            "TokenNFTConnector: ZERO_ADDRESS"
        );
        require(token != _pairToken, "TokenNFTConnector: SAME_TOKENS_IN_PAIR");
        swapRouter = _swapRouter;
        delayVaultProvider = _delayVaultProvider;
        pairToken = _pairToken;
        poolFee = _poolFee;
    }

    function createLeaderboard(
        uint256 amountIn,
        SwapParams[] calldata poolsData
    ) external whenNotPaused nonReentrant returns (uint256 amountOut) {
        IERC20 tokenToSwap = (poolsData.length > 0)
            ? IERC20(poolsData[0].token)
            : pairToken;
        require(
            tokenToSwap.allowance(msg.sender, address(this)) >= amountIn,
            "TokenNFTConnector: no allowance"
        );

        tokenToSwap.transferFrom(msg.sender, address(this), amountIn);
        tokenToSwap.approve(address(swapRouter), amountIn);

        amountOut = swapRouter.exactInput(
            ISwapRouter.ExactInputParams({
                path: getBytes(poolsData),
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0
            })
        );
        amountOut = calcMinusFee(amountOut);
        require(
            checkIncreaseLevel(amountOut),
            "TokenNFTConnector: please update your tier level"
        );
        token.approve(address(delayVaultProvider), amountOut);
        uint256[] memory delayParams = new uint256[](1);
        delayParams[0] = amountOut;
        delayVaultProvider.createNewDelayVault(msg.sender, delayParams);
    }

    function getBytes(
        SwapParams[] calldata data
    ) public view returns (bytes memory result) {
        for (uint256 i; i < data.length; ++i) {
            require(
                data[i].token != address(0),
                "TokenNFTConnector: ZERO_ADDRESS"
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

    function checkIncreaseLevel(uint256 additionalAmount) public view returns (bool) {
        uint256 userAmount = delayVaultProvider.getTotalAmount(msg.sender);
        return delayVaultProvider.theTypeOf(userAmount + additionalAmount) == delayVaultProvider.theTypeOf(userAmount);
    }
}
