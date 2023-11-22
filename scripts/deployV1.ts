import { ethers, upgrades } from "hardhat";
import { Crowdfunding, ICrowdfunding } from "../typechain-types";


async function main() {
   const provider = new ethers.JsonRpcProvider("https://rpc-mumbai.maticvigil.com");
   const owner = new ethers.Wallet(String(process.env.PRIVATE_KEY), provider);

   const V1Contract = await ethers.getContractFactory("Crowdfunding");
   console.log("Deploying Crowdfunding V1...");
   const v1Contract = await upgrades.deployProxy(V1Contract, [], {
      initializer: "initialize",
   });
   await v1Contract.waitForDeployment();
   console.log("V1 Contract deployed to:", await v1Contract.getAddress());

   const USDC = await ethers.getContractFactory("USDC");
   const usdc = await USDC.deploy();
   await usdc.waitForDeployment();

   console.log("USDC ADDRESS : " + await usdc.getAddress());

   const mintAmount = ethers.parseUnits("1000000", 18);
   let result = await usdc.connect(owner).mint(mintAmount);
   await result.wait();
   console.log("Minted 1000000 USDC");

   result = await v1Contract.addNewSupportedToken(await usdc.getAddress(), { from: owner.address });
   await result.wait();
   console.log("Added USDC to supported tokens");

   let result2 = await v1Contract.createProject(SetupProjectData(owner.address,  await usdc.getAddress(), ethers.parseUnits("100000", 18), "Help Give Us", "GiveUs"), SetupTresholdData(ethers.parseEther("100000")), { from: owner.address });
   await result.wait();
   console.log("Created project 1");

   //await CreateProjects(v1Contract as Crowdfunding, await usdc.getAddress());
}

async function CreateProjects(crowdfunding: Crowdfunding, exchangeToken: string) {
   const provider = new ethers.JsonRpcProvider("https://rpc-mumbai.maticvigil.com");
   const owner = new ethers.Wallet(String(process.env.PRIVATE_KEY), provider);

   let result = await crowdfunding.createProject(SetupProjectData(owner.address, exchangeToken, ethers.parseUnits("100000", 18), "Help Give Us", "GiveUs"), SetupTresholdData(ethers.parseEther("100000")), { from: owner.address });
   await result.wait();
   console.log("Created project 1");

   /*
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
   console.log("Created project 12");*/
}

function SetupProjectData(owner: string, exchangeToken: string, requiredAmountToFund: bigint, name: string, assoName: string) {
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

function SetupTresholdData(requiredAmountToFund: bigint) {

   const voteSession: ICrowdfunding.VoteSessionStruct = {
      isVotingInSession: false,
      positiveVotes: 0,
      negativeVotes: 0,
   }

   const amount: bigint = requiredAmountToFund / 10n;

   const treshold1: ICrowdfunding.ThresholdStruct = {
      budget: amount,
      voteSession: voteSession
   }

   const treshold2: ICrowdfunding.ThresholdStruct = {
      budget: amount * 2n,
      voteSession: voteSession
   }

   const treshold3: ICrowdfunding.ThresholdStruct = {
      budget: amount* 3n,
      voteSession: voteSession
   }

   const treshold4: ICrowdfunding.ThresholdStruct = {
      budget: amount* 4n,
      voteSession: voteSession
   }

   const treshold5: ICrowdfunding.ThresholdStruct = {
      budget: amount* 5n,
      voteSession: voteSession
   }

   const treshold6: ICrowdfunding.ThresholdStruct = {
      budget: amount* 6n,
      voteSession: voteSession
   }

   const treshold7: ICrowdfunding.ThresholdStruct = {
      budget: amount* 7n,
      voteSession: voteSession
   }

   const treshold8: ICrowdfunding.ThresholdStruct = {
      budget: amount* 8n,
      voteSession: voteSession
   }

   const treshold9: ICrowdfunding.ThresholdStruct = {
      budget: amount* 9n,
      voteSession: voteSession
   }

   const treshold10: ICrowdfunding.ThresholdStruct = {
      budget: amount* 10n,
      voteSession: voteSession
   }

   const tresholds: ICrowdfunding.ThresholdStruct[] = [treshold1, treshold2, treshold3, treshold4, treshold5, treshold6, treshold7, treshold8, treshold9, treshold10];

   return tresholds;
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
});