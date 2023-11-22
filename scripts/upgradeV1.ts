import { ethers, upgrades } from "hardhat";

const UPGRADEABLE_PROXY = ""; //"Insert your proxy contract address here";

async function main() {
   const V2Contract = await ethers.getContractFactory("CrowdFundingV2");
   console.log("Upgrading V1Contract...");
   let upgrade = await upgrades.upgradeProxy(UPGRADEABLE_PROXY, V2Contract);
   console.log("V1 Upgraded to V2");
   console.log("V2 Contract Deployed To:", upgrade.address)
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });