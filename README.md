# Crowdfunding contract
## Installation:
- Clone gitHub repository
- Install dependencies

```sh
$ npm install
```

- Launch Local bc node

```sh
$ npx hardhat node
```

- Launch UnitTests/Coverage

```sh
$ npx hardhat coverage
```

## Dev Environment:
Contracts created/tested/compiled with hardhat. Hardhat node is used to create a local blockchain for testing purposes.
Other tools used include :
- chai + hardhat-chai-matchers
- ethers + hardhat-ethers
- hardhat-gas-reporter
- hardhat-gas-reporter
- solidity-coverage
- openzeppelin contracts and test-helpers


## Summary:
The Crowdfunding.sol smart contract is designed to manage donations, fund allocation, and voting for project milestones.
Give Us helps people donate to projects that they love and be able to have a say in where the funds go.

### The features are as follows : 
- Team members (UPDATER_ROLE) can create projects, with a combination of parameters including goal tresholds
- Team members (WITHDRAWER_ROLE) can withdraw the fees collected
- Team members (PAUSER_ROLE) can pause/unpause the contract
- Users can donate to projects, becoming donators of said project.
- Whenever a project's curent donation amount is superior to a goal treshold a vote session is started.
- Donators of a project can vote during during said project's vote sessions.
- After a certain amount of time Team members (UPDATER_ROLE) can end a vote, it will start deliberation.
- If vote is successfull, the amount allocated to that treshold will be retrievable by the project's owner.
- If vote is not successfull, the vote session will reset and enter a cooldown.
- Once a Project's goal is finished and fully voted Team members (UPDATER_ROLE) can disable the project if needed.

### Emergency Features:
- Pausable Contract
- Upgradable Contract 
- Team members (UPDATER_ROLE) can transfer funds donated from a project to another

## Explanation with a bit more details: 
### Project and Treshold Structures:
The smart contract uses two main structures, Project and Treshold. The Project structure contains information about each project, such as owner, project name, token address, donation fee, and more. The Treshold structure contains information about a project's milestones or stages and voting sessions for these milestones.

### Creation and Management of Projects:
The smart contract allows Team members (UPDATER_ROLE) to create new projects with specified attributes like name, description, milestones, and donation fee. Updaters can also update the status of projects, set donation fees, and modify vote cooldowns.

### Donations to Projects:
Users can donate to projects using the project's supported token. The smart contract checks for allowance, project status, and minimum donation amount. A small transaction fee is deducted from the donation, and the remaining funds are added to the project's current amount. If the project's current amount meets the budget of the next milestone, a voting session is initiated.

### Voting Sessions and Tresholds:
When a project reaches a milestone's budget, a voting session is started for that milestone. Donators can vote in the session, and their votes are recorded. Once the voting session is over, the votes are deliberated, and if the required vote percentage is met, funds are released to be withdrawn by the project owner. If the vote fails, the vote session is reset, and a new voting session can start after the cooldown period.


### Fund Withdrawals and Transfers:
Project owners can withdraw funds if they have available funds to withdraw. The contract checks if the project owner's address matches the project's owner address and if there are available funds. Additionally, funds can be transferred from one project to another by an authorized role (UPDATER_ROLE). This is intended for emergency situations and deactivates the source project after the transfer.

The contract also uses OpenZeppelin's upgradeability features to ensure that future updates can be made without compromising the storage layout.

The Admins (UPDATER_ROLE) can withdraw the fees collected by the contract.

### Security and Emergency procedures

To avoid any issues regarding the stealing of private keys or risk of scam from team members, the UPDATER_ROLE, which has the most power, will only be given to a multisig wallet which will require at least 3 team members to sign to make any transactions.

In regards to the security of the contract, the team is able to pause the contract and updgrade it to fix any bug encountered.

In case of emergency the team can use the UPDATER_ROLE to transfer the funds from one project to another.

Such cases of emergency can be but are not limited to : 
- A project owner that was supposedly honest at first, decides to take the first installement of the donor's donations and not continue to work on the project. 

In that case, the team will freeze the project in question, and the remaining donations on it will be redistributed to another project (project that can be decided by the community).