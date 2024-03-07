import { ethers, upgrades } from "hardhat";
import { Crowdfunding, ICrowdfunding } from "../typechain-types";


async function main() {
   const provider = new ethers.JsonRpcProvider("https://rpc-mumbai.maticvigil.com");
   const owner = new ethers.Wallet(String(process.env.PRIVATE_KEY), provider);

   const ownerAddress = await owner.getAddress();

   const crowdfunding = await ethers.getContractAt("Crowdfunding", "0x555ccE60F3A60CD5804FC9941F9B140722eB3380");
   const usdcAddress = "0xd7483FD127Da6676262150bbe82EA8D42dC296c0"

   /*console.log("proejct Data : " + SetupProjectData("0x5d253624bDd9FE09ab8B95824B1217125025e57a", usdcAddress, ethers.parseEther("25000"), "Fight the fire", "Orgatest"));
   console.log("treshold Data : " + SetupCustomTresholdData());*/

   let result = await crowdfunding.connect(owner).createProject(SetupProjectData("0x5d253624bDd9FE09ab8B95824B1217125025e57a", usdcAddress, ethers.parseEther("25000"), "Fight Against the Fire", "Orgatest"), SetupCustomTresholdData());
   await result.wait();
   console.log("Created project 1");
   let result1 = await crowdfunding.connect(owner).createProject(SetupProjectData("0x5d253624bDd9FE09ab8B95824B1217125025e57a", usdcAddress, ethers.parseEther("100000"), "Ice Guard", "Orgatest"), SetupCustomTresholdData2());
   await result1.wait();
   console.log("Created project 2");
}
/*
("0x5d253624bDd9FE09ab8B95824B1217125025e57a","0xd7483FD127Da6676262150bbe82EA8D42dC296c0","Fight the fire", "Orgatest", "MyDescription", 25000000000000000000000, 50, 60, 50)

[(5000,(false,0,0)),(10000,(false,0,0)),(25000,(false,0,0))]*/
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

function SetupCustomTresholdData() {

   const voteSession: ICrowdfunding.VoteSessionStruct = {
      isVotingInSession: false,
      positiveVotes: 0,
      negativeVotes: 0,
   }

   const treshold1: ICrowdfunding.ThresholdStruct = {
      budget: ethers.parseUnits("5000"),
      voteSession: voteSession
   }

   const treshold2: ICrowdfunding.ThresholdStruct = {
      budget: ethers.parseUnits("10000"),
      voteSession: voteSession
   }

   const treshold3: ICrowdfunding.ThresholdStruct = {
      budget: ethers.parseUnits("25000"),
      voteSession: voteSession
   }

   const tresholds: ICrowdfunding.ThresholdStruct[] = [treshold1, treshold2, treshold3];

   return tresholds;
}

function SetupCustomTresholdData2() {

   const voteSession: ICrowdfunding.VoteSessionStruct = {
      isVotingInSession: false,
      positiveVotes: 0,
      negativeVotes: 0,
   }

   const treshold1: ICrowdfunding.ThresholdStruct = {
      budget:  ethers.parseUnits("20000"),
      voteSession: voteSession
   }

   const treshold2: ICrowdfunding.ThresholdStruct = {
      budget:  ethers.parseUnits("40000"),
      voteSession: voteSession
   }

   const treshold3: ICrowdfunding.ThresholdStruct = {
      budget:  ethers.parseUnits("60000"),
      voteSession: voteSession
   }

   const treshold4: ICrowdfunding.ThresholdStruct = {
      budget:  ethers.parseUnits("80000"),
      voteSession: voteSession
   }

   const treshold5: ICrowdfunding.ThresholdStruct = {
      budget:  ethers.parseUnits("100000"),
      voteSession: voteSession
   }

   const tresholds: ICrowdfunding.ThresholdStruct[] = [treshold1, treshold2, treshold3, treshold4, treshold5];

   return tresholds;
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