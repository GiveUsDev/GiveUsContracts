import { ethers, defender } from "hardhat";

async function main() {
  const CrowdfundingV2 = await ethers.getContractFactory("CrowdfundingV2");
  const proxyAddress = '0x936E6aEF9A5907Dc0de39d2Ecb0D25f0B5929F15';
  const proposal = await defender.proposeUpgradeWithApproval(proxyAddress, CrowdfundingV2);

  console.log(`Upgrade proposed with URL: ${proposal.url}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});