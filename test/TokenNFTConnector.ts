import { SwapperMock, DelayMock } from "../typechain-types"
import { ERC20Token } from "../typechain-types/@poolzfinance/poolz-helper-v2/contracts/token/ERC20Token"
import { TokenNFTConnector } from "../typechain-types/contracts/TokenNFTConnector"
import { deployed } from "@poolzfinance/poolz-helper-v2"
import { expect } from "chai"
import { ethers } from "hardhat"

describe("TokenNFTConnector", function () {
    let tokenNFTConnector: TokenNFTConnector
    let token: ERC20Token
    let tokenToSwap: ERC20Token
    let swapRouter: SwapperMock
    let delayVaultProvider: DelayMock
    let owner: SignerWithAddress

    before(async () => {
        ;[owner] = await ethers.getSigners()
        const TokenToSwap = await ethers.deployContract("ERC20Token", ["TEST", "test"])
        const SwapRouter = await ethers.deployContract("SwapperMock")
        const DelayVaultProvider = await ethers.deployContract("DelayMock")
        const Token = await ethers.deployContract("ERC20Token", ["TEST", "test"])
        token = await Token.deployed()
        swapRouter = await SwapRouter.deployed()
        delayVaultProvider = await DelayVaultProvider.deployed()
        tokenNFTConnector = await ethers.deployContract("TokenNFTConnector", [
            token.address,
            swapRouter.address,
            delayVaultProvider.address,
            `0`,
            `0`,
        ])
    })

    it("temp ", async () => {})
})
