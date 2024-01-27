# TokenNFTConnector

[![Build and Test](https://github.com/The-Poolz/TokenNFTConnector/actions/workflows/node.js.yml/badge.svg)](https://github.com/The-Poolz/TokenNFTConnector/actions/workflows/node.js.yml)
[![codecov](https://codecov.io/gh/The-Poolz/TokenNFTConnector/graph/badge.svg)](https://codecov.io/gh/The-Poolz/TokenNFTConnector)
[![CodeFactor](https://www.codefactor.io/repository/github/the-poolz/TokenNFTConnector/badge)](https://www.codefactor.io/repository/github/the-poolz/TokenNFTConnector)

Contract that is integrated with `Pancakeswap` to exchange any tokens for `POOLX DelayVault NFT`.

### Navigation

-   [Installation](#installation)
-   [How it works?](#how-it-works)
-   [UML](#contracts-uml)
-   [License](#license)

## Installation

**Install the packages:**

```console
npm i
```

```console
yarn
```

**Compile contracts:**

```console
npx hardhat compile
```

**Run tests:**

```console
npx hardhat test
```

**Run coverage:**

```console
npx hardhat coverage
```

## How it works?

The **TokenNFTConnector** contract operates in the following steps:

1. **Token Swap:**

    - Users call the `createLeaderboard` function, providing the amount of tokens they want to swap and an array of `SwapParams` specifying the tokens to swap through and their.
    - The contract uses PancakeSwap's router (`ISwapRouter`) to execute the token swap. It calculates the path based on the provided swap parameters and swaps the tokens, considering the pool fees.

2. **Fee Deduction:**

    - The contract calculates the remaining amount after deducting the project owner fee using the `calcMinusFee` function.

3. **DelayVault Creation:**

    - The remaining amount after fees is then approved for the `DelayVaultProvider` contract.
    - The contract calls `createNewDelayVault` on the `DelayVaultProvider`, associating the newly created `DelayVault` with the user.

4. **Result:**
    - Users receive a `POOLX DelayVault NFT` associated with the [POOLX](https://bscscan.com/token/0xbaea9aba1454df334943951d51116ae342eab255) tokens.

## Contracts UML

![classDiagram](https://github.com/The-Poolz/LockDealNFT.DelayVaultProvider/assets/68740472/1610209b-61ce-41ac-9485-cb7d92e49235)

## License

[The-Poolz](https://poolz.finance/) Contracts is released under the [MIT License](https://github.com/The-Poolz/TokenNFTConnector/blob/master/LICENSE).