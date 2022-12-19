import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');


describe("Crowdfunding Contract", function () {
  async function deployCrowdfundingFixture() {
    const Crowdfunding = await ethers.getContractFactory("Crowdfunding");
    const [owner, addr1, addr2] = await ethers.getSigners();

    const crowdfunding = await Crowdfunding.deploy();

    await crowdfunding.deployed();

    // Fixtures can return anything you consider useful for your tests
    return { Crowdfunding, crowdfunding, owner, addr1, addr2 };
  }
  async function deployUSDCFixture() {
    const USDC = await ethers.getContractFactory("USDC");

    const usdc = await USDC.deploy();

    await usdc.deployed();

    return { USDC, usdc };
  }
  async function createProjectDataAndUSDCFixture() {
    const { Crowdfunding, crowdfunding, owner, addr1, addr2 } = await loadFixture(deployCrowdfundingFixture);
    const { USDC, usdc } = await loadFixture(deployUSDCFixture);

    const requiredAmountToFund = 300000;

    const voteSession = {
      isVotingInSession: false,
      positiveVotes: 0,
      negativeVotes: 0,
    }

    const treshold1 = {
      budget: 50000,
      voteSession: voteSession
    }

    const treshold2 = {
      budget: 100000,
      voteSession: voteSession
    }

    const treshold3 = {
      budget: 150000,
      voteSession: voteSession
    }

    const tresholds = [treshold1, treshold2, treshold3];
    const emptyTresholds = [treshold1];
    emptyTresholds.pop();

    let projectData = {
      owner: owner.address,
      exchangeTokenAddress: usdc.address,
      name: "MyProjectName",
      assoName: "MyAssoName",
      teamMembers: ["TeamMember1", "TeamMember2"],
      description: "MyDescription",
      requiredAmount: requiredAmountToFund,
      requiredVotePercentage: 50
    };

    return { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc };
  }
  async function createProjectAndUSDCFixture() {
    const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc } = await loadFixture(createProjectDataAndUSDCFixture);
    await crowdfunding.AddNewSupportedToken(usdc.address, { from: owner.address });
    await crowdfunding.CreateProject(projectData, tresholds, { from: owner.address });
    return { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc };
  }
  async function createProjectAndDonateMaxFixture() {
    const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc } = await loadFixture(createProjectAndUSDCFixture);
    const mintAmount = 100000;
    const donatedAmount = 100000;
    const projectID = 0;
    await usdc.mint(mintAmount);
    await usdc.approve(crowdfunding.address, mintAmount);
    await crowdfunding.DonateToProject(projectID, donatedAmount);
    return { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc, mintAmount, donatedAmount, projectID };
  }
  async function createProjectAndFundFixture() {
    const { Crowdfunding, crowdfunding, owner, addr1, addr2 } = await loadFixture(deployCrowdfundingFixture);
    const { USDC, usdc } = await loadFixture(deployUSDCFixture);

    const requiredAmountToFund = 100000;
    const voteSession = {
      isVotingInSession: false,
      positiveVotes: 0,
      negativeVotes: 0,
    }
    const treshold1 = {
      budget: 100000,
      voteSession: voteSession
    }
    const tresholds = [treshold1];

    let projectData = {
      owner: owner.address,
      exchangeTokenAddress: usdc.address,
      name: "MyProjectName",
      assoName: "MyAssoName",
      teamMembers: ["TeamMember1", "TeamMember2"],
      description: "MyDescription",
      requiredAmount: requiredAmountToFund,
      requiredVotePercentage: 50
    };

    await crowdfunding.AddNewSupportedToken(usdc.address, { from: owner.address });
    await crowdfunding.CreateProject(projectData, tresholds, { from: owner.address });
    const mintAmount = requiredAmountToFund;
    const donatedAmount = requiredAmountToFund;
    const projectID = 0;
    await usdc.mint(mintAmount);
    await usdc.approve(crowdfunding.address, mintAmount);
    await crowdfunding.DonateToProject(projectID, donatedAmount);
    await crowdfunding.StartTresholdVoting(projectID);
    await crowdfunding.VoteForTreshold(projectID, true);
    await crowdfunding.EndTresholdVoting(projectID);
    return { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, USDC, usdc, mintAmount, donatedAmount, projectID };
  }
  async function createProjectAndDonateFixture() {
    const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc } = await loadFixture(createProjectAndUSDCFixture);
    const mintAmount = 100000;
    const donatedAmount = 20000;
    const projectID = 0;
    await usdc.mint(mintAmount);
    await usdc.approve(crowdfunding.address, mintAmount);
    await crowdfunding.DonateToProject(projectID, donatedAmount);
    return { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc, mintAmount, donatedAmount, projectID };
  }
  async function createProjectAndStartedVotingFixture() {
    const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc, projectID } = await loadFixture(createProjectAndDonateMaxFixture);
    await crowdfunding.StartTresholdVoting(projectID);
    const treshold = await crowdfunding.projectsTresholds(projectID, 0);
    expect(treshold.voteSession.isVotingInSession).to.be.equal(true);
    return { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc, projectID };
  }
  async function DonateToProject3AndVote() {
    const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc } = await loadFixture(createProjectAndUSDCFixture);
    const mintAmount = 100000;
    const donatedAmount = 100000;
    const projectID = 0;
    await usdc.mint(mintAmount);
    await usdc.approve(crowdfunding.address, mintAmount);
    await crowdfunding.DonateToProject(projectID, donatedAmount);

    await usdc.connect(addr1).mint(mintAmount);
    await usdc.connect(addr1).approve(crowdfunding.address, mintAmount);
    await crowdfunding.connect(addr1).DonateToProject(projectID, donatedAmount);

    await usdc.connect(addr2).mint(mintAmount);
    await usdc.connect(addr2).approve(crowdfunding.address, mintAmount);
    await crowdfunding.connect(addr2).DonateToProject(projectID, donatedAmount);

    await crowdfunding.StartTresholdVoting(projectID);
    const treshold = await crowdfunding.projectsTresholds(projectID, 0);
    expect(treshold.voteSession.isVotingInSession).to.be.equal(true);

    return { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc, mintAmount, donatedAmount, projectID };
  }

  describe("Deployment", function () {
    describe("USDC mint(uint amount)", function () {
      it("Should mint amount", async function () {
        const { owner, usdc } = await loadFixture(createProjectDataAndUSDCFixture);
        const amount = 10000;
        await usdc.mint(amount);
        expect(await usdc.balanceOf(owner.address)).to.be.equal(amount);
      });
    });
    describe("Constructor()", function () {
      it("Should grant role DEFAULT_ADMIN_ROLE", async function () {
        const { crowdfunding, owner, addr1, addr2 } = await loadFixture(deployCrowdfundingFixture);
        let DEFAULT_ADMIN_ROLE = await crowdfunding.DEFAULT_ADMIN_ROLE({ from: owner.address });
        expect(await crowdfunding.hasRole(DEFAULT_ADMIN_ROLE, owner.address, { from: owner.address })).to.equal(true);
      });

      it("Should grant role PAUSER_ROLE", async function () {
        const { crowdfunding, owner, addr1, addr2 } = await loadFixture(deployCrowdfundingFixture);
        let PAUSER_ROLE = await crowdfunding.PAUSER_ROLE({ from: owner.address });
        expect(await crowdfunding.hasRole(PAUSER_ROLE, owner.address, { from: owner.address })).to.equal(true);
      });

      it("Should grant role PAUSER_ROLE", async function () {
        const { crowdfunding, owner, addr1, addr2 } = await loadFixture(deployCrowdfundingFixture);
        let UPDATER_ROLE = await crowdfunding.UPDATER_ROLE({ from: owner.address });
        expect(await crowdfunding.hasRole(UPDATER_ROLE, owner.address, { from: owner.address })).to.equal(true);
      });
    });
    describe("CreateProject(Project calldata _project)", function () {
      it("Should not create project, revert : Token not supported", async function () {
        const { crowdfunding, owner, addr1, addr2, projectData, tresholds } = await loadFixture(createProjectDataAndUSDCFixture);
        await expectRevert(crowdfunding.CreateProject(projectData, tresholds, { from: owner.address }), "Token not supported");
      });

      it("Should not create project, revert : Need at least one Treshold", async function () {
        const { crowdfunding, owner, addr1, addr2, projectData, emptyTresholds, usdc } = await loadFixture(createProjectDataAndUSDCFixture);
        await crowdfunding.AddNewSupportedToken(usdc.address, { from: owner.address });
        await expectRevert(crowdfunding.CreateProject(projectData, emptyTresholds, { from: owner.address }), "Need at least one Treshold");
      });

      it("Should create project", async function () {
        const { crowdfunding, owner, addr1, addr2, projectData, tresholds, usdc } = await loadFixture(createProjectDataAndUSDCFixture);

        await crowdfunding.AddNewSupportedToken(usdc.address, { from: owner.address });
        await crowdfunding.CreateProject(projectData, tresholds, { from: owner.address });

        const projectDataReturned = await crowdfunding.projects(0, { from: owner.address });

        expect(projectData.owner).to.be.equal(projectDataReturned.owner);
        expect(projectData.exchangeTokenAddress).to.be.equal(projectDataReturned.exchangeTokenAddress);
        expect(projectData.name).to.be.equal(projectDataReturned.name);
        expect(projectData.assoName).to.be.equal(projectDataReturned.assoName);
        expect(projectData.description).to.be.equal(projectDataReturned.description);
        expect(projectData.requiredAmount).to.be.equal(projectDataReturned.requiredAmount);
        expect(projectDataReturned.currentAmount).to.be.equal(0);
        expect(projectDataReturned.currentTreshold).to.be.equal(0);
        expect(projectDataReturned.nbOfTresholds).to.be.equal(3);
        expect(projectData.requiredVotePercentage).to.be.equal(projectDataReturned.requiredVotePercentage);

        for (let i = 0; i < 3; i++) {
          const tresholdDataReturned = await crowdfunding.projectsTresholds(0, i);
          expect(tresholdDataReturned.budget).to.be.equal(tresholds[i].budget);

          const returnedVotingSession = tresholdDataReturned.voteSession;
          const votingSession = tresholds[i].voteSession;
          expect(returnedVotingSession.isVotingInSession).to.be.equal(votingSession.isVotingInSession);
          expect(returnedVotingSession.positiveVotes).to.be.equal(votingSession.positiveVotes);
          expect(returnedVotingSession.negativeVotes).to.be.equal(votingSession.negativeVotes);
        }

        //TODO Handle teammembers
        //expect(projectData.teamMembers).to.be.equal(projectDataReturned.teamMembers);
      });
    });
    describe("AddNewSupportedToken(address tokenAddress)", function () {
      it("Should not add token, revert : AccessControl is missing role", async function () {
        const { crowdfunding, owner, addr1, addr2 } = await loadFixture(deployCrowdfundingFixture);
        const tokenAddress = owner.address;

        let UPDATER_ROLE = await crowdfunding.connect(addr1).UPDATER_ROLE();

        await expectRevert(crowdfunding.connect(addr1).AddNewSupportedToken(tokenAddress),
          "AccessControl: account " +
          addr1.address.toLowerCase() +
          " is missing role " +
          UPDATER_ROLE
        );
      });

      it("Should add token", async function () {
        const { crowdfunding, owner, addr1, addr2 } = await loadFixture(deployCrowdfundingFixture);
        const tokenAddress = owner.address;

        await crowdfunding.AddNewSupportedToken(tokenAddress);
        const token = await crowdfunding.IsTokenSupported(tokenAddress);
        await expect(token).to.be.equal(true);
      });
    });
    describe("DonateToProject(uint id, uint amount)", function () {
      it("Shouldnt donate, revert : Min amount is 1", async function () {
        const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc } = await loadFixture(createProjectAndUSDCFixture);
        await expectRevert(crowdfunding.DonateToProject(0, 0), "Min amount is 1");
      });
      it("Shouldnt donate, revert : Project not Active", async function () {
        const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc } = await loadFixture(createProjectDataAndUSDCFixture);
        await expectRevert(crowdfunding.DonateToProject(0, 10), "Project not Active");
      });
      it("Shouldnt donate, revert : Need to approve allowance first", async function () {
        const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc } = await loadFixture(createProjectAndUSDCFixture);
        const mintAmount = 100000;
        await usdc.mint(mintAmount);
        await expectRevert(crowdfunding.DonateToProject(0, 20000), "Need to approve allowance first");
      });
      it("Shouldnt donate, revert : Amount too small", async function () {
        const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc } = await loadFixture(createProjectAndUSDCFixture);
        const mintAmount = 100000;
        await usdc.mint(mintAmount);
        await expectRevert(crowdfunding.DonateToProject(0, 5000), "Amount too small");
      });
      it("Shouldnt donate, revert : Cant go above Donation Goal", async function () {
        const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc } = await loadFixture(createProjectAndUSDCFixture);
        const mintAmount = 1000000;
        await usdc.mint(mintAmount);
        await usdc.approve(crowdfunding.address, mintAmount);
        await expectRevert(crowdfunding.DonateToProject(0, 1000000), "Cant go above Donation Goal");
      });
      it("Should donate", async function () {
        const { crowdfunding, owner, usdc, mintAmount, donatedAmount, projectID } = await loadFixture(createProjectAndDonateFixture);

        expect(await usdc.balanceOf(owner.address)).to.be.equal(mintAmount - donatedAmount);
        expect(await usdc.balanceOf(crowdfunding.address)).to.be.equal(donatedAmount);

        expect(await crowdfunding.userDonations(owner.address, projectID)).to.be.equal(donatedAmount);
        const project0 = await crowdfunding.projects(projectID);
        expect(project0.currentAmount).to.be.equal(donatedAmount);
      });
    });
    describe("IsDonator(address user, uint256 id)", function () {
      it("Should Return true", async function () {
        const { crowdfunding, owner, projectID } = await loadFixture(createProjectAndDonateFixture);
        expect(await crowdfunding.IsDonator(owner.address, projectID)).to.be.equal(true);
      });
    });
    describe("IsTokenSupported(address token)", function () {
      it("Should Return true", async function () {
        const { crowdfunding, usdc } = await loadFixture(createProjectAndUSDCFixture);
        expect(await crowdfunding.IsTokenSupported(usdc.address)).to.be.equal(true);
      });
      it("Should Return true", async function () {
        const { crowdfunding, owner } = await loadFixture(createProjectAndUSDCFixture);
        expect(await crowdfunding.IsTokenSupported(owner.address)).to.be.equal(false);
      });
    });
    describe("VoteForTreshold(uint256 id, bool vote)", function () {
      it("Shouldnt vote, revert : Only Donators can vote", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndStartedVotingFixture);
        await expectRevert(crowdfunding.connect(addr1).VoteForTreshold(projectID,true), "Only Donators can vote");
      });
      it("Shouldnt vote, revert : Not in Voting Session", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndDonateFixture);
        await expectRevert(crowdfunding.VoteForTreshold(projectID,true), "Not in Voting Session");
      });
      it("Shouldnt vote, revert : Can Only Vote Once", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndStartedVotingFixture);
        await crowdfunding.VoteForTreshold(projectID,true);
        await expectRevert(crowdfunding.VoteForTreshold(projectID,true), "Can Only Vote Once");
      });
      it("Should vote positive", async function () {
        const { crowdfunding, owner, projectID } = await loadFixture(createProjectAndStartedVotingFixture);
        const positiveVotes = await (await crowdfunding.projectsTresholds(projectID,0)).voteSession.positiveVotes;
        const hasVoted = false;
        await crowdfunding.VoteForTreshold(projectID,true);
        expect((await crowdfunding.projectsTresholds(projectID,0)).voteSession.positiveVotes).to.be.equal(positiveVotes+BN(1));
        expect(await crowdfunding.tresholdVoteFromAddress(owner.address,projectID,0)).to.be.equal(!hasVoted);
      });
      it("Should vote negative", async function () {
        const { crowdfunding, owner, projectID } = await loadFixture(createProjectAndStartedVotingFixture);
        const negativeVotes = await (await crowdfunding.projectsTresholds(projectID,0)).voteSession.negativeVotes;
        const hasVoted = false;
        await crowdfunding.VoteForTreshold(projectID,false);
        expect((await crowdfunding.projectsTresholds(projectID,0)).voteSession.negativeVotes).to.be.equal(negativeVotes+BN(1));
        expect(await crowdfunding.tresholdVoteFromAddress(owner.address,projectID,0)).to.be.equal(!hasVoted);
      });
    });
    describe("StartTresholdVoting(uint256 id)", function () {
      it("Shouldnt start voting, revert : You are not allowed", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndDonateFixture);
        await expectRevert(crowdfunding.connect(addr1).StartTresholdVoting(projectID), "You are not allowed");
      });

      it("Shouldnt start voting, revert : Already in Voting Session", async function () {
        const { crowdfunding, projectID } = await loadFixture(createProjectAndDonateMaxFixture);
        await crowdfunding.StartTresholdVoting(projectID);
        await expectRevert(crowdfunding.StartTresholdVoting(projectID), "Already in Voting Session");
      });

      it("Shouldnt start voting, revert : Project Funded or Inactive", async function () {
        const { crowdfunding, projectID } = await loadFixture(createProjectAndFundFixture);
        await expectRevert(crowdfunding.StartTresholdVoting(projectID), "Project Funded or Inactive");
      });

      it("Shouldnt start voting, revert : Treshold not reached yet", async function () {
        const { crowdfunding, projectID } = await loadFixture(createProjectAndDonateFixture);
        await expectRevert(crowdfunding.StartTresholdVoting(projectID), "Treshold not reached yet");
      });

      it("Should start voting", async function () {
        const { crowdfunding, projectID } = await loadFixture(createProjectAndDonateMaxFixture);
        await crowdfunding.StartTresholdVoting(projectID);
        const treshold = await crowdfunding.projectsTresholds(projectID, 0);
        expect(treshold.voteSession.isVotingInSession).to.be.equal(true);
      });
    });
    describe("EndTresholdVoting(uint256 id)", function () {
      it("Shouldnt end voting, revert : You are not allowed", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndStartedVotingFixture);
        await expectRevert(crowdfunding.connect(addr1).EndTresholdVoting(projectID), "You are not allowed");
      });
      it("Shouldnt end voting, revert : Not in Voting Session", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndDonateFixture);
        await expectRevert(crowdfunding.EndTresholdVoting(projectID), "Not in Voting Session");
      });
      it("Should end voting, & set voting session false", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndStartedVotingFixture);
        await crowdfunding.VoteForTreshold(projectID, true);
        await crowdfunding.EndTresholdVoting(projectID);
        const treshold = await crowdfunding.projectsTresholds(projectID, 0);
        expect(treshold.voteSession.isVotingInSession).to.be.equal(false);
      });
    });
    describe("DeliberateVote(uint256 id)", function () {
      it("Shouldnt deliberate, revert : Cant deliberate without votes", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndStartedVotingFixture);
        await expectRevert(crowdfunding.EndTresholdVoting(projectID), "Cant deliberate without votes");
      });
      it("Should deliberate positive 1-0", async function () {
        const { crowdfunding, owner, usdc, projectID } = await loadFixture(createProjectAndStartedVotingFixture);
        const currentTreshold = 0;
        const tresholdBudget = (await crowdfunding.projectsTresholds(projectID, currentTreshold)).budget;
        expect ((await crowdfunding.projects(projectID)).currentTreshold).to.be.equal(currentTreshold);
        await crowdfunding.VoteForTreshold(projectID, true);
        await crowdfunding.EndTresholdVoting(projectID);
        const treshold = await crowdfunding.projectsTresholds(projectID, currentTreshold);
        expect(treshold.voteSession.isVotingInSession).to.be.equal(false);
        expect ((await crowdfunding.projects(projectID)).currentTreshold).to.be.equal(currentTreshold+1);
        expect (await crowdfunding.availableWithdrawals(owner.address,usdc.address)).to.be.equal(tresholdBudget);
      });

      it("Should deliberate negative whith 0-1", async function () {
        const { crowdfunding, owner, usdc, projectID } = await loadFixture(createProjectAndStartedVotingFixture);
        const currentTreshold = 0;
        const tresholdBudget = (await crowdfunding.projectsTresholds(projectID, currentTreshold)).budget;
        const availableToWithdraw = await crowdfunding.availableWithdrawals(owner.address,usdc.address);
        expect ((await crowdfunding.projects(projectID)).currentTreshold).to.be.equal(currentTreshold);
        await crowdfunding.VoteForTreshold(projectID, false);
        await crowdfunding.EndTresholdVoting(projectID);
        const treshold = await crowdfunding.projectsTresholds(projectID, currentTreshold);
        expect(treshold.voteSession.isVotingInSession).to.be.equal(false);
        expect ((await crowdfunding.projects(projectID)).currentTreshold).to.be.equal(currentTreshold);
        expect (await crowdfunding.availableWithdrawals(owner.address,usdc.address)).to.be.equal(availableToWithdraw);
      });

      it("Should deliberate equal whith 1-1 with 50%", async function () {
        const { crowdfunding, owner, addr1, usdc, projectID } = await loadFixture(DonateToProject3AndVote);
        const currentTreshold = 0;
        const tresholdBudget = (await crowdfunding.projectsTresholds(projectID, currentTreshold)).budget;
        const availableToWithdraw = await crowdfunding.availableWithdrawals(owner.address,usdc.address);
        expect ((await crowdfunding.projects(projectID)).currentTreshold).to.be.equal(currentTreshold);

        await crowdfunding.VoteForTreshold(projectID, true);
        await crowdfunding.connect(addr1).VoteForTreshold(projectID, false);

        await crowdfunding.EndTresholdVoting(projectID);
        const treshold = await crowdfunding.projectsTresholds(projectID, currentTreshold);
        expect(treshold.voteSession.isVotingInSession).to.be.equal(false);
        expect ((await crowdfunding.projects(projectID)).currentTreshold).to.be.equal(currentTreshold);
        expect (await crowdfunding.availableWithdrawals(owner.address,usdc.address)).to.be.equal(availableToWithdraw);
      });
      
    });
    describe("WithdrawFunds(address exchangeTokenAddress)", function () {
      it("Shouldnt WithdrawFunds, revert : No Funds to withdraw", async function () {
        const { crowdfunding, usdc, projectID } = await loadFixture(createProjectAndDonateFixture);
        await expectRevert(crowdfunding.WithdrawFunds(usdc.address), "No Funds to withdraw");
      });

      it("Shouldnt WithdrawFunds, revert : Token not supported", async function () {
        const { crowdfunding, owner, projectID } = await loadFixture(createProjectAndDonateFixture);
        await expectRevert(crowdfunding.WithdrawFunds(owner.address), "Token not supported");
      });

      it("Should WithdrawFunds", async function () {
        const { crowdfunding, usdc, owner, projectID } = await loadFixture(createProjectAndFundFixture);
        const balance = await usdc.balanceOf(owner.address);
        const availableToWithdraw = await crowdfunding.availableWithdrawals(owner.address,usdc.address);
        await crowdfunding.WithdrawFunds(usdc.address);
        const newBalance = await usdc.balanceOf(owner.address)
        const shouldNewBalance = balance.toNumber() + availableToWithdraw.toNumber();
        expect(newBalance.toNumber()).to.be.equal(shouldNewBalance);
      });
    });

  });
});
