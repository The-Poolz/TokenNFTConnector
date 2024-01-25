import { SwapperMock, DelayMock } from "../typechain-types"
import { ERC20Token } from "../typechain-types/@poolzfinance/poolz-helper-v2/contracts/token/ERC20Token"
import { TokenNFTConnector } from "../typechain-types/contracts/TokenNFTConnector"
import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"

describe("TokenNFTConnector", function () {
    let tokenNFTConnector: TokenNFTConnector
    let token: ERC20Token
    let pairToken: ERC20Token
    let tokenToSwap: ERC20Token
    let swapRouter: SwapperMock
    let delayVaultProvider: DelayMock
    let owner: SignerWithAddress
    const amount = ethers.utils.parseUnits("100", 18)
    const data = ethers.utils.defaultAbiCoder.encode(["uint256"], [amount])
    const poolFee = `3000`

    before(async () => {
        ;[owner] = await ethers.getSigners()
        const TokenToSwap = (await ethers.deployContract("ERC20Token", ["TEST", "test"])) as ERC20Token
        const SwapRouter = (await ethers.deployContract("SwapperMock")) as SwapperMock
        const Token = (await ethers.deployContract("ERC20Token", ["TEST", "test"])) as ERC20Token
        token = await Token.deployed()
        const PairToken = (await ethers.deployContract("ERC20Token", ["USDT", "usdt"])) as ERC20Token
        pairToken = await PairToken.deployed()
        const DelayVaultProvider = (await ethers.deployContract("DelayMock")) as DelayMock
        swapRouter = await SwapRouter.deployed()
        delayVaultProvider = await DelayVaultProvider.deployed()
        tokenToSwap = await TokenToSwap.deployed()
        tokenNFTConnector = (await ethers.deployContract("TokenNFTConnector", [
            token.address,
            pairToken.address,
            swapRouter.address,
            delayVaultProvider.address,
            poolFee,
            `0`,
        ])) as TokenNFTConnector
        // approve token to swap
        await tokenToSwap.approve(tokenNFTConnector.address, ethers.utils.parseUnits("100000", 18))
    })

    it("should increase delay NFT counter", async () => {
        const currentCounter = await delayVaultProvider.counter()
        const packedData = ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [tokenToSwap.address, "100"])
        await tokenNFTConnector.connect(owner).createLeaderboard(packedData, amount)
        expect(await delayVaultProvider.counter()).to.equal(currentCounter.add(1))
    })

    it("should increase user delay amount", async () => {
        const user = await ethers.provider.getSigner(1)
        const userAddress = await user.getAddress()
        await tokenToSwap.transfer(userAddress, amount)
        await tokenToSwap.connect(user).approve(tokenNFTConnector.address, amount)
        const packedData = ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [tokenToSwap.address, "100"])
        await tokenNFTConnector.connect(user).createLeaderboard(packedData, amount)
        expect(await delayVaultProvider.ownerToAmount(userAddress)).to.equal(amount.mul(2))
    })

    it("should revert if no allowance", async () => {
        const user = await ethers.provider.getSigner(2)
        await expect(tokenNFTConnector.connect(user).createLeaderboard("0x", amount)).to.be.revertedWith(
            "TokenNFTConnector: no allowance"
        )
    })
})
