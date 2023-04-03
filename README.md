# Crowdfunding contract

Summary:
The provided smart contract is designed to manage donations, fund allocation, and voting for project milestones. Users can donate to projects, and project owners can withdraw funds when certain criteria are met. Voting sessions are held to deliberate on project milestones, and project owners can only withdraw funds after receiving approval in the voting sessions.

Project and Treshold Structures:
The smart contract uses two main structures, Project and Treshold. The Project structure contains information about each project, such as owner, project name, token address, donation fee, and more. The Treshold structure contains information about a project's milestones or stages and voting sessions for these milestones.

Creation and Management of Projects:
The smart contract allows Team members (UPDATER_ROLE) to create new projects with specified attributes like name, description, milestones, and donation fee. Updaters can also update the status of their projects, set donation fees, and modify vote cooldowns.

Donations to Projects:
Users can donate to projects using the project's supported token. The smart contract checks for allowance, project status, and minimum donation amount. A small transaction fee is deducted from the donation, and the remaining funds are added to the project's current amount. If the project's current amount meets the budget of the next milestone, a voting session is initiated.

Voting Sessions and Tresholds:
When a project reaches a milestone's budget, a voting session is started for that milestone. Donators can vote in the session, and their votes are recorded. Once the voting session is over, the votes are deliberated, and if the required vote percentage is met, funds are released to the project owner. If the vote fails, the vote session is reset, and a new voting session can start after the cooldown period.

Fund Withdrawals and Transfers:
Project owners can withdraw funds if they have available funds to withdraw. The contract checks if the project owner's address matches the project's owner address and if there are available funds. Additionally, funds can be transferred from one project to another by an authorized role (UPDATER_ROLE). This is intended for emergency situations and deactivates the source project after the transfer.

Supported Tokens and Roles:
The smart contract supports adding new tokens, and only specific roles (UPDATER_ROLE, PAUSER_ROLE) can perform certain actions like updating project attributes or pausing the contract. 

The contract also uses OpenZeppelin's upgradeability features to ensure that future updates can be made without compromising the storage layout.
