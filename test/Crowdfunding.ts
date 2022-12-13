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

  async function createProjectAndDonateFixture() {
    const { Crowdfunding, crowdfunding, owner, addr1, addr2, projectData, tresholds, emptyTresholds, USDC, usdc } = await loadFixture(createProjectAndUSDCFixture);
    const mintAmount = 100000;
    const donatedAmount = 10000;
    const projectID = 0;
    await usdc.mint(mintAmount);
    await usdc.approve(crowdfunding.address, mintAmount);
    await crowdfunding.DonateToProject(projectID, donatedAmount);
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
        await expectRevert(crowdfunding.DonateToProject(0, 1000), "Need to approve allowance first");
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

    describe("StartTresholdVoting(uint256 id)", function () {
      it("Shouldnt start voting, revert : You are not allowed", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndDonateFixture);
        await expectRevert(crowdfunding.connect(addr1).StartTresholdVoting(projectID), "You are not allowed");
      });
      //TODO
      it("Shouldnt start voting, revert : Already in Voting Session", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndDonateFixture);

      });
      //TODO
      it("Shouldnt start voting, revert : Project Funded", async function () {
        const { crowdfunding, addr1, projectID } = await loadFixture(createProjectAndDonateFixture);

      });
      //TODO
      it("Shouldnt start voting, revert : Treshold not reached yet", async function () {
        const { crowdfunding, projectID } = await loadFixture(createProjectAndDonateFixture);
        await expectRevert(crowdfunding.StartTresholdVoting(projectID), "Treshold not reached yet");
      });
    });

  });
});
