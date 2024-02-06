import { ethers, upgrades } from "hardhat"

async function main() {
    //const POOLX = "0xbAeA9aBA1454DF334943951d51116aE342eAB255"
    //const delayVaultProvider = "0xeb88Ff7799E0e7b187D98232336722ec9936B86D"
    //const smartRouter = "0x13f4EA83D0bd40E75C8222255bc855a974568Dd4"
    //const USDT = "0x55d398326f99059fF775485246999027B3197955"

    const POOLXTestnet = "0xE14A2A1006B83F363569BC7b5b733191E919ca34"
    const USDTTestnet = "0x337610d27c682E347C9cD60BD4b3b107C9d34dDd"
    const delayVaultProviderTestnet = "0x9fd743f499d852E3A2cFEAC037e5562126468D28"
    const smartRouterTestnet = "0x9a489505a00cE272eAa5e07Dba6491314CaE3796"
    const poolFee = "100"

    const tokenNFTConnector = await ethers.getContractFactory("TokenNFTConnector")
    const proxy = await upgrades.deployProxy(
        tokenNFTConnector,
        [POOLXTestnet, USDTTestnet, delayVaultProviderTestnet, smartRouterTestnet, poolFee, 0],
        { initializer: "initialize" }
    )
    await proxy.waitForDeployment()
    console.log("Proxy deployed to:", await proxy.getAddress())
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
