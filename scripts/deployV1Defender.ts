import { ethers, defender } from "hardhat";

async function main() {
  const Crowdfunding = await ethers.getContractFactory("Crowdfunding");

  const upgradeApprovalProcess = await defender.getUpgradeApprovalProcess();

  if (upgradeApprovalProcess.address === undefined) {
    throw new Error(`Upgrade approval process with id ${upgradeApprovalProcess.approvalProcessId} has no assigned address`);
  }

  const adminAddress = upgradeApprovalProcess.address;
  console.log(`Admin address: ${adminAddress}`);
  const deployment = await defender.deployProxy(Crowdfunding, [adminAddress], { initializer: "initialize" });

  console.log(`Deploying Crowdfunding V1 to upgrade approval process ${upgradeApprovalProcess.approvalProcessId}...`);
  await deployment.waitForDeployment();
  console.log(`Contract deployed to ${await deployment.getAddress()}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});