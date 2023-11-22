import { ethers, upgrades } from "hardhat";
import { BigNumber } from "ethers";
import { Crowdfunding, ICrowdfunding } from "../typechain-types";


async function main() {
   const provider = new ethers.providers.JsonRpcProvider("https://rpc-mumbai.maticvigil.com");
   const owner = new ethers.Wallet(String(process.env.PRIVATE_KEY), provider);

   const V1Contract = await ethers.getContractFactory("Crowdfunding");
   console.log("Deploying Crowdfunding V1...");
   const v1Contract = await upgrades.deployProxy(V1Contract, [], {
      initializer: "initialize",
   });
   await v1Contract.deployed();
   console.log("V1 Contract deployed to:", v1Contract.address);

   const USDC = await ethers.getContractFactory("USDC");
   const usdc = await USDC.deploy();
   await usdc.deployed();

   console.log("USDC ADDRESS : " + usdc.address);

   const mintAmount = ethers.utils.parseUnits("1000000", 18);
   let result = await usdc.connect(owner).mint(mintAmount);
   await result.wait();
   console.log("Minted 1000000 USDC");

   result = await v1Contract.addNewSupportedToken(usdc.address, { from: owner.address });
   await result.wait();
   console.log("Added USDC to supported tokens");

   await CreateProjects(v1Contract as Crowdfunding, usdc.address);
}

async function CreateProjects(crowdfunding: Crowdfunding, exchangeToken: string) {
   const provider = new ethers.providers.JsonRpcProvider("https://rpc-mumbai.maticvigil.com");
   const owner = new ethers.Wallet(String(process.env.PRIVATE_KEY), provider);

   let result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("12000", 18), "Desa'a Forest", "Orga Name"), SetupTresholdData(ethers.utils.parseEther("12000")), { from: owner.address });
   await result.wait();
   console.log("Created project 1");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("500000", 18), 'Fight against deforestation', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("500000")), { from: owner.address });
   await result.wait();
   console.log("Created project 2");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("35000", 18), 'Garbage cleaning', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("35000")), { from: owner.address });
   await result.wait();
   console.log("Created project 3");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("28000", 18), 'Promote education', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("28000")), { from: owner.address });
   await result.wait();
   console.log("Created project 4");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("800000", 18), 'Hospital construction', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("800000")), { from: owner.address });
   await result.wait();
   console.log("Created project 5");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("150000", 18), 'Water Treatment', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("150000")), { from: owner.address });
   await result.wait();
   console.log("Created project 6");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("500000", 18), 'Marine life preservation', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("500000")), { from: owner.address });
   await result.wait();
   console.log("Created project 7");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("1000000", 18), 'Natural reserve', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("1000000")), { from: owner.address });
   await result.wait();
   console.log("Created project 8");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("1500000", 18), 'Global warning research', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("1500000")), { from: owner.address });
   await result.wait();
   console.log("Created project 9");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("68000", 18), 'Tribe protection', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("68000")), { from: owner.address });
   await result.wait();
   console.log("Created project 10");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("45000", 18), 'Village electrification', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("45000")), { from: owner.address });
   await result.wait();
   console.log("Created project 11");
   result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.utils.parseUnits("200000", 18), 'Clean water', "Orga Name"), SetupTresholdData(ethers.utils.parseEther("200000")), { from: owner.address });
   await result.wait();
   console.log("Created project 12");
}

function SetupProjectData(owner: string, exchangeToken: string, requiredAmountToFund: BigNumber, name: string, assoName: string) {
   let projectData = {
      owner: owner,
      exchangeTokenAddress: exchangeToken,
      name: name,
      assoName: assoName,
      description: "MyDescription",
      requiredAmount: requiredAmountToFund,
      requiredVotePercentage: 50,
      voteCooldown: 60,
      donationFee: 50
   };

   return projectData;
}

function SetupTresholdData(requiredAmountToFund: BigNumber) {

   const voteSession: ICrowdfunding.VoteSessionStruct = {
      isVotingInSession: false,
      positiveVotes: 0,
      negativeVotes: 0,
   }

   const amount: BigNumber = requiredAmountToFund.div(5);

   const treshold1: ICrowdfunding.ThresholdStruct = {
      budget: amount,
      voteSession: voteSession
   }

   const treshold2: ICrowdfunding.ThresholdStruct = {
      budget: amount.mul(2),
      voteSession: voteSession
   }

   const treshold3: ICrowdfunding.ThresholdStruct = {
      budget: amount.mul(3),
      voteSession: voteSession
   }

   const treshold4: ICrowdfunding.ThresholdStruct = {
      budget: amount.mul(4),
      voteSession: voteSession
   }

   const treshold5: ICrowdfunding.ThresholdStruct = {
      budget: amount.mul(5),
      voteSession: voteSession
   }

   const tresholds: ICrowdfunding.ThresholdStruct[] = [treshold1, treshold2, treshold3, treshold4, treshold5];

   return tresholds;
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
});