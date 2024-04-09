// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@poolzfinance/poolz-helper-v2/contracts/Nameable.sol";
import "./interfaces/IDelayVaultProvider.sol";
import "./interfaces/ISwapRouter.sol";
import "./ConnectorManageable.sol";

contract TokenNFTConnector is ConnectorManageable, ReentrancyGuard, Nameable {
    using SafeERC20 for IERC20;

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
            "TokenNFTConnector: zero address"
        );
        require(token != _pairToken, "TokenNFTConnector: same tokens in pair");
        swapRouter = _swapRouter;
        delayVaultProvider = _delayVaultProvider;
        pairToken = _pairToken;
        poolFee = _poolFee;
    }

    function createLeaderboard(
        uint256 amountIn,
        uint256 amountOutMinimum,
        SwapParams[] calldata poolsData
    ) external whenNotPaused nonReentrant returns (uint256 amountOut) {
        IERC20 tokenToSwap = (poolsData.length > 0)
            ? IERC20(poolsData[0].token)
            : pairToken;
        require(
            tokenToSwap.allowance(msg.sender, address(this)) >= amountIn,
            "TokenNFTConnector: no allowance"
        );
        uint256 amountBeforeSwap = tokenToSwap.balanceOf(address(this));
        tokenToSwap.safeTransferFrom(msg.sender, address(this), amountIn);
        uint256 receivedAmount = tokenToSwap.balanceOf(address(this)) - amountBeforeSwap;
        tokenToSwap.safeIncreaseAllowance(address(swapRouter), amountIn);
        amountOut = swapRouter.exactInput(
            ISwapRouter.ExactInputParams({
                path: getBytes(poolsData),
                recipient: address(this),
                amountIn: receivedAmount,
                amountOutMinimum: amountOutMinimum
            })
        );
        amountOut = calcMinusFee(amountOut);
        require(amountOut >= amountOutMinimum, "TokenNFTConnector: insufficient output amount");
        require(
            !checkIncreaseTier(msg.sender, amountOut),
            "TokenNFTConnector: please update your tier level"
        );
        token.safeIncreaseAllowance(address(delayVaultProvider), amountOut);
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

    function checkIncreaseTier(address user, uint256 additionalAmount) public view returns (bool) {
        uint256 userAmount = delayVaultProvider.getTotalAmount(user);
        return delayVaultProvider.theTypeOf(userAmount + additionalAmount) > delayVaultProvider.theTypeOf(userAmount);
    }
}
