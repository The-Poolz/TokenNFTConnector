import { SwapperMock, DelayMock } from "../typechain-types"
import { ERC20Token } from "../typechain-types/@poolzfinance/poolz-helper-v2/contracts/token/ERC20Token"
import { TokenNFTConnector } from "../typechain-types/contracts/TokenNFTConnector"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { ethers } from "hardhat"

describe("Connector Manageable", function () {
    let tokenNFTConnector: TokenNFTConnector
    let token: ERC20Token
    let owner: SignerWithAddress
    let swapRouter: SwapperMock
    let delayVaultProvider: DelayMock

    before(async () => {
        ;[owner] = await ethers.getSigners()
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
            `3000`,
            `0`,
        ])
    })

    it("should set owner address after creation", async () => {
        const ownerAddress = await tokenNFTConnector.owner()
        expect(ownerAddress).to.equal(await ethers.provider.getSigner(0).getAddress())
    })

    it("should pause contract", async () => {
        await tokenNFTConnector.connect(owner).pause()
        expect(await tokenNFTConnector.paused()).to.equal(true)
    })

    it("should unpause contract", async () => {
        await tokenNFTConnector.connect(owner).unpause()
        expect(await tokenNFTConnector.paused()).to.equal(false)
    })

    it("should set fee amount", async () => {
        await tokenNFTConnector.connect(owner).setFee(100)
        expect(await tokenNFTConnector.projectOwnerFee()).to.equal(100)
    })

    it("should pause createLeaderboard", async () => {
        await tokenNFTConnector.connect(owner).pause()
        await expect(tokenNFTConnector.connect(owner).createLeaderboard(token.address, "1000")).to.be.revertedWith(
            "Pausable: paused"
        )
    })

    it("owner can't set invalid fee amount", async () => {
        await expect(tokenNFTConnector.connect(owner).setFee(10001)).to.be.revertedWith(
            "ConnectorManageable: invalid fee"
        )
    })

    it("should return the amount after deducting fee", async () => {
        await tokenNFTConnector.connect(owner).setFee(1000)
        expect(await tokenNFTConnector.connect(owner).calcMinusFee(1000)).to.equal(900)
    })
})
