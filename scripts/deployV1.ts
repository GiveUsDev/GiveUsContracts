import { ethers, upgrades } from "hardhat";

async function main() {
   const gas = await ethers.provider.getGasPrice()
   const V1Contract = await ethers.getContractFactory("CrowdFunding");
   console.log("Deploying CrowdFunding V1...");
   const v1Contract = await upgrades.deployProxy(V1Contract, [10], {
      gasPrice: gas, 
      initializer: "initialize",
   });
   await v1Contract.deployed();
   console.log("V1 Contract deployed to:", v1Contract.address);
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });