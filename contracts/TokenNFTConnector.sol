// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@poolzfinance/poolz-helper-v2/contracts/Nameable.sol";
import "./interfaces/IDelayVaultProvider.sol";
import "./interfaces/ISwapRouter.sol";
import "./ConnectorManageable.sol";

contract TokenNFTConnector is ConnectorManageable, ReentrancyGuard, Nameable {
    using SafeERC20 for IERC20;

    event LeaderboardCreated(address indexed user, uint256 amountIn, bytes path, uint256 amountOut);

    error SameTokensInPair();
    error NoAllowance(uint256 amountIn, uint256 allowance);
    error InsufficientOutputAmount();
    error UpdateYourTier(uint256 amountOut);

    ISwapRouter public immutable swapRouter;
    IDelayVaultProvider public immutable delayVaultProvider;
    IERC20 public immutable pairToken;
    uint24 private immutable poolFee; // last pair fee

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
        if (address(_token) == address(0)) revert NoZeroAddress();
        if (address(_pairToken) == address(0)) revert NoZeroAddress();
        if (address(_swapRouter) == address(0)) revert NoZeroAddress();
        if (token == _pairToken) revert SameTokensInPair();
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

        uint256 allowance = tokenToSwap.allowance(msg.sender, address(this));
        if (allowance < amountIn) revert NoAllowance(amountIn, allowance);

        uint256 amountBeforeSwap = tokenToSwap.balanceOf(address(this));
        tokenToSwap.safeTransferFrom(msg.sender, address(this), amountIn);
        uint256 receivedAmount = tokenToSwap.balanceOf(address(this)) - amountBeforeSwap;
        // Reset allowance to zero before increasing to use USDT
        tokenToSwap.forceApprove(address(swapRouter), 0);
        // Increase allowance using SafeERC20's safeIncreaseAllowance
        tokenToSwap.safeIncreaseAllowance(address(swapRouter), receivedAmount);
        bytes memory path = getBytes(poolsData);
        amountOut = swapRouter.exactInput(
            ISwapRouter.ExactInputParams({
                path: path,
                recipient: address(this),
                amountIn: receivedAmount,
                amountOutMinimum: amountOutMinimum
            })
        );
        amountOut = calcMinusFee(amountOut);
        if (amountOut < amountOutMinimum) revert InsufficientOutputAmount();
        if (checkIncreaseTier(msg.sender, amountOut)) revert UpdateYourTier(amountOut);

        // Delay vault only works with POOLX token so no need to reset allowance
        // Increase allowance
        token.safeIncreaseAllowance(address(delayVaultProvider), amountOut);

        uint256[] memory delayParams = new uint256[](1);
        delayParams[0] = amountOut;
        delayVaultProvider.createNewDelayVault(msg.sender, delayParams);

        emit LeaderboardCreated(msg.sender, amountIn, path, amountOut);
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
