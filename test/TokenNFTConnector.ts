import { SwapperMock, DelayMock } from "../typechain-types"
import { ERC20Token } from "../typechain-types/@poolzfinance/poolz-helper-v2/contracts/token/ERC20Token"
import { TokenNFTConnector } from "../typechain-types/contracts/TokenNFTConnector"
import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"

describe("TokenNFTConnector", function () {
    let tokenNFTConnector: TokenNFTConnector
    let token: ERC20Token
    let tokenToSwap: ERC20Token
    let swapRouter: SwapperMock
    let delayVaultProvider: DelayMock
    let owner: SignerWithAddress
    const amount = ethers.utils.parseUnits("100", 18)
    const data = ethers.utils.defaultAbiCoder.encode(["uint256"], [amount])

    before(async () => {
        ;[owner] = await ethers.getSigners()
        const TokenToSwap = (await ethers.deployContract("ERC20Token", ["TEST", "test"])) as ERC20Token
        const SwapRouter = (await ethers.deployContract("SwapperMock")) as SwapperMock
        const Token = (await ethers.deployContract("ERC20Token", ["TEST", "test"])) as ERC20Token
        token = await Token.deployed()
        const DelayVaultProvider = (await ethers.deployContract("DelayMock")) as DelayMock
        swapRouter = await SwapRouter.deployed()
        delayVaultProvider = await DelayVaultProvider.deployed()
        tokenToSwap = await TokenToSwap.deployed()
        tokenNFTConnector = (await ethers.deployContract("TokenNFTConnector", [
            token.address,
            swapRouter.address,
            delayVaultProvider.address,
            `0`,
        ])) as TokenNFTConnector
        // approve token to swap
        await tokenToSwap.approve(tokenNFTConnector.address, ethers.utils.parseUnits("100000", 18))
    })

    it("should increase delay NFT counter", async () => {
        const currentCounter = await delayVaultProvider.counter()
        await tokenNFTConnector.connect(owner).createLeaderboard(tokenToSwap.address, amount, [data])
        expect(await delayVaultProvider.counter()).to.equal(currentCounter.add(1))
    })

    it("should increase user delay amount", async () => {
        const user = await ethers.provider.getSigner(1)
        const userAddress = await user.getAddress()
        await tokenToSwap.transfer(userAddress, amount)
        await tokenToSwap.connect(user).approve(tokenNFTConnector.address, amount)
        await tokenNFTConnector.connect(user).createLeaderboard(tokenToSwap.address, amount, [data])
        expect(await delayVaultProvider.ownerToAmount(userAddress)).to.equal(amount.mul(2))
    })

    it("should revert if no allowance", async () => {
        const user = await ethers.provider.getSigner(2)
        await expect(
            tokenNFTConnector.connect(user).createLeaderboard(tokenToSwap.address, amount, [data])
        ).to.be.revertedWith("TokenNFTCoonector: no allowance")
    })
})
