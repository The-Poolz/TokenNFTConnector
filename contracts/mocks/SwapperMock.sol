// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISwapRouter.sol";

contract SwapperMock is ISwapRouter {
    function multicall(
        bytes[] calldata data
    ) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        results[data.length - 1] = abi.encode(100);
    }
}
