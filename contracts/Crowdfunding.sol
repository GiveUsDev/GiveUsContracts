// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title A Crowdfunding Contract
 * @author Ludovic Domingues
 * @notice Contract used for Looting Plateform
 * @dev All function calls are currently implemented without side effects
 */
contract Crowdfunding is AccessControl, Pausable {
    using Counters for Counters.Counter;

    /**
     * @dev The following constants are used by AccessControl to check authorisations.
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    /**
     * @notice Event emited whenever a new project is created
     * @param projectID The id of the project
     * @param owner The owner of said project
     * @param projectName The name of the project
     */
    event ProjectCreated(uint256 projectID, address owner, string projectName);

    /**
     * @notice Event emited whenever a project receives a new donation
     * @param donatorAddress The donor's address
     * @param projectId The id of the project
     * @param donationAmount The amount donated in wei
     */
    event DonatedToProject(
        address donatorAddress,
        uint256 projectId,
        uint256 donationAmount
    );

    /**
     * @notice Event emited whenever a project owner withdraws its funds
     * @param projectOwnerAddress The project owner's address
     * @param exchangeTokenAddress The address of the IERC20 contract
     * @param amountToWithdraw The amount withdrawn in wei
     */
    event WithdrewFunds(
        address projectOwnerAddress,
        address exchangeTokenAddress,
        uint256 amountToWithdraw
    );

    /**
     * @notice Event emited whenever a project owner withdraws its funds
     * @param tokenAddress The address of the IERC20 contract
     */
    event NewSupportedTokenAdded(address tokenAddress);

    /**
     * @notice Event emited whenever an admin changes the Donation Fee
     * @param projectId The project's ID
     * @param newFee The new donationFee amount
     */
    event DonationFeeUpdated(uint256 projectId, uint16 newFee);

    /**
     * @notice Event emited whenever a project is deactivated
     * @param projectId The project's ID
     * @param newStatus The new status of the project
     */
    event ProjectStatusUpdated(uint256 projectId, bool newStatus);

    modifier validProjectId(uint256 id) {
        require(idCounter.current() > id, "Invalid Id");
        _;
    }

    modifier validTresholdId(uint256 projectId, uint256 tresholdId) {
        Project memory project = projects[projectId];
        require(project.nbOfTresholds > tresholdId, "Invalid Treshold Id");
        _;
    }

    struct Treshold {
        uint256 budget;
        VoteSession voteSession;
    }

    struct VoteSession {
        bool isVotingInSession;
        uint256 positiveVotes;
        uint256 negativeVotes;
    }

    /**
     * @notice Data Struct used to create a new project
     */
    struct ProjectData {
        address owner;
        address exchangeTokenAddress;
        string name;
        string assoName;
        string description;
        uint256 requiredAmount;
        uint256 requiredVotePercentage; // must be in basis points like 1% = 100 / 100% = 10000 / 0.01% = 1
        uint16 donationFee;
    }

    /**
     * @notice Struct used to create a new project
     */
    struct Project {
        bool active;
        address owner;
        address exchangeTokenAddress;
        string name;
        string assoName;
        string description;
        uint256 requiredAmount;
        uint256 currentAmount;
        uint256 currentTreshold;
        uint256 nbOfTresholds;
        uint256 requiredVotePercentage; // must be in integer like 50% = 50 28% = 28
        uint16 donationFee;
    }

    mapping(address => bool) private supportedTokens;
    mapping(uint256 => Project) private projects; //get project by id
    mapping(uint256 => mapping(uint256 => Treshold)) private projectsTresholds; //get project by id and treshold by id // each treshold has its own budget like [10,20,30] this means the total budget is 10+20+30 //can add alter a function to add new tresholds
    mapping(address => mapping(uint256 => uint256)) private userDonations;
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        private tresholdVoteFromAddress;
    mapping(uint256 => mapping(uint256 => address[]))
        private voterArrayForTreshold;
    mapping(address => mapping(address => uint256))
        private availableWithdrawals;

    Counters.Counter private idCounter;

    /**
     * @notice Constructor used to set the default roles
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `PAUSER_ROLE`, `UPDATER_ROLE` and `WITHDRAWER_ROLE` to the msg.sender
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
        _grantRole(WITHDRAWER_ROLE, msg.sender);
    }

    /**
     * @notice Function used to Create a new Project
     * @param projectData Data used to create project
     * @param tresholds Array of threshold for the project
     */
    function createProject(
        ProjectData calldata projectData,
        Treshold[] calldata tresholds
    ) external onlyRole(UPDATER_ROLE) whenNotPaused {
        require(
            isTokenSupported(projectData.exchangeTokenAddress),
            "Token not supported"
        );
        require(tresholds.length > 0, "Need at least one Treshold");
        require(projectData.requiredAmount > 0);
        uint256 currentId = idCounter.current();
        projects[currentId] = Project(
            true,
            projectData.owner,
            projectData.exchangeTokenAddress,
            projectData.name,
            projectData.assoName,
            projectData.description,
            projectData.requiredAmount,
            0,
            0,
            tresholds.length,
            projectData.requiredVotePercentage,
            projectData.donationFee
        );

        for (uint256 i = 0; i < tresholds.length; i++) {
            projectsTresholds[currentId][i] = tresholds[i];
        }

        idCounter.increment();

        emit ProjectCreated(currentId, projectData.owner, projectData.name);
    }

    /**
     * @notice Function returning if a user is a donator or not
     * @param user user address
     * @param id project id
     * @return bool is user a donator
     */
    function isDonator(address user, uint256 id)
        public
        view
        validProjectId(id)
        returns (bool)
    {
        return userDonations[user][id] > 0;
    }

    /**
     * @notice Function that checks if token is supported by the contract as an exchange token
     * @param token address of the token you want to check
     * @return bool is token supported
     */
    function isTokenSupported(address token) public view returns (bool) {
        return supportedTokens[token];
    }

    /**
     * @notice Function that returns the project data of a given projectId
     * @param projectId ID of the project
     * @return Project the data for the given project
     */
    function getProject(uint256 projectId)
        external
        view
        validProjectId(projectId)
        returns (Project memory)
    {
        return projects[projectId];
    }

    /**
     * @notice Function that returns the project treshold of a given projectId and tresholdId
     * @param projectId ID of the project
     * @param tresholdId ID of the treshold
     * @return Treshold the treshold for the given projectId && tresholdId
     */
    function getProjectTresholds(uint256 projectId, uint256 tresholdId)
        external
        view
        validProjectId(projectId)
        validTresholdId(projectId, tresholdId)
        returns (Treshold memory)
    {
        return projectsTresholds[projectId][tresholdId];
    }

    /**
     * @notice Function that returns donated amount from a donatorAddress to a project
     * @param donatorAddress address of the donator
     * @param projectId ID of the project
     * @return uint donated amount
     */
    function getUserDonations(address donatorAddress, uint256 projectId)
        external
        view
        validProjectId(projectId)
        returns (uint256)
    {
        return userDonations[donatorAddress][projectId];
    }

    /**
     * @notice Function that returns if a donator has voted on a treshold
     * @param voterAddress address of the donator/voter
     * @param projectId ID of the project
     * @param tresholdId ID of the treshold
     * @return bool has voted ?
     */
    function getTresholdVoteFromAddress(
        address voterAddress,
        uint256 projectId,
        uint256 tresholdId
    )
        external
        view
        validProjectId(projectId)
        validTresholdId(projectId, tresholdId)
        returns (bool)
    {
        return tresholdVoteFromAddress[voterAddress][projectId][tresholdId];
    }

    /**
     * @notice Function that returns the amount that user can withdraw for given token
     * @param userAddress address of the user
     * @param erc20ContractAddress Address of the ERC20 token
     * @return uint amount available to withdraw
     */
    function getAvailableWithdrawals(
        address userAddress,
        address erc20ContractAddress
    ) external view returns (uint256) {
        return availableWithdrawals[userAddress][erc20ContractAddress];
    }

    /**
     * @notice Triggers stopped state
     */
    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    /**
     * @notice Returns to normal state
     */
    function unpause() external onlyRole(PAUSER_ROLE) whenPaused {
        _unpause();
    }

    /**
     * @notice Donate amount of tokens to project id
     * @param projectId ID of the project
     * @param amount amount to donate
     */
    function donateToProject(uint256 projectId, uint256 amount)
        external
        whenNotPaused
        validProjectId(projectId)
    {
        require(amount > 0, "Min amount is 1");
        Project memory project = projects[projectId];
        require(project.active, "Project not Active");
        require((amount / 10000) * 10000 == amount, "Amount too small");

        address tokenSupported = project.exchangeTokenAddress;

        require(
            IERC20(tokenSupported).allowance(msg.sender, address(this)) >=
                amount,
            "Need to approve allowance first"
        );

        uint256 transactionFee = (amount * project.donationFee) / 10000;
        uint256 donationAmount = amount - transactionFee;

        userDonations[msg.sender][projectId] += donationAmount;
        projects[projectId].currentAmount += donationAmount;

        project = projects[projectId];
        Treshold memory currentTreshold = projectsTresholds[projectId][
            project.currentTreshold
        ];

        if (
            project.currentAmount >= currentTreshold.budget &&
            !currentTreshold.voteSession.isVotingInSession &&
            project.currentTreshold < project.nbOfTresholds
        ) {
            startTresholdVoting(projectId);
        }

        bool result = IERC20(tokenSupported).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(result, "Transfer failed");

        emit DonatedToProject(msg.sender, projectId, donationAmount);
    }

    /**
     * @notice Function that starts a vote session for a treshold
     * @param id ID of the project
     */
    function endTresholdVoting(uint256 id)
        external
        onlyRole(UPDATER_ROLE)
        whenNotPaused
        validProjectId(id)
    {
        Project memory project = projects[id];
        Treshold memory currentTreshold = projectsTresholds[id][
            project.currentTreshold
        ];
        require(
            currentTreshold.voteSession.isVotingInSession,
            "Not in Voting Session"
        );

        projectsTresholds[id][project.currentTreshold]
            .voteSession
            .isVotingInSession = false;

        deliberateVote(id);
    }

    /**
     * @notice Function that allows a donator to vote for the current treshold of a project
     * @param id ID of the project
     * @param vote true for positive vote, false for negative vote
     */
    function voteForTreshold(uint256 id, bool vote)
        external
        whenNotPaused
        validProjectId(id)
    {
        Project memory project = projects[id];
        Treshold memory currentTreshold = projectsTresholds[id][
            project.currentTreshold
        ];
        bool hasVoted = tresholdVoteFromAddress[msg.sender][id][
            project.currentTreshold
        ];
        require(isDonator(msg.sender, id), "Only Donators can vote");
        require(
            currentTreshold.voteSession.isVotingInSession,
            "Not in Voting Session"
        );
        require(!hasVoted, "Can Only Vote Once");

        VoteSession memory vs = currentTreshold.voteSession;
        vote ? vs.positiveVotes++ : vs.negativeVotes++;

        projectsTresholds[id][project.currentTreshold].voteSession = vs;
        tresholdVoteFromAddress[msg.sender][id][project.currentTreshold] = true;
        voterArrayForTreshold[id][project.currentTreshold].push(msg.sender);
    }

    /**
     * @notice Function that allows a project owner to withdraw his funds
     * @param exchangeTokenAddress Address of the ERC20 token
     */
    function withdrawFunds(address exchangeTokenAddress)
        external
        whenNotPaused
    {
        require(isTokenSupported(exchangeTokenAddress), "Token not supported");
        uint256 amountToWithdraw = availableWithdrawals[msg.sender][
            exchangeTokenAddress
        ];
        require(amountToWithdraw > 0, "No Funds to withdraw");

        availableWithdrawals[msg.sender][exchangeTokenAddress] = 0;

        bool result = IERC20(exchangeTokenAddress).transfer(
            msg.sender,
            amountToWithdraw
        );
        require(result, "Transfer failed");
        emit WithdrewFunds(msg.sender, exchangeTokenAddress, amountToWithdraw);
    }

    /**
     * @notice Function that adds a new supported token
     * @param tokenAddress Address of the ERC20 token
     */
    function addNewSupportedToken(address tokenAddress)
        external
        onlyRole(UPDATER_ROLE)
    {
        supportedTokens[tokenAddress] = true;
        emit NewSupportedTokenAdded(tokenAddress);
    }

    /**
     * @notice Function that sets the donation fee for a project
     * @param projectId ID of the project
     * @param newFee New fee to set
     */
    function setDonationFee(uint256 projectId, uint16 newFee)
        external
        onlyRole(UPDATER_ROLE)
        validProjectId(projectId)
    {
        require(newFee < 10000, "Cant go above 10000");
        projects[projectId].donationFee = newFee;
        emit DonationFeeUpdated(projectId, newFee);
    }

    /**
     * @notice Function that sets the project status
     * @param projectId ID of the project
     * @param newStatus New status to set
     */
    function UpdateProjectStatus(uint256 projectId, bool newStatus)
        external
        onlyRole(UPDATER_ROLE)
        validProjectId(projectId)
    {
        projects[projectId].active = newStatus;
        emit ProjectStatusUpdated(projectId, newStatus);
    }

    function startTresholdVoting(uint256 id)
        private
        whenNotPaused
        validProjectId(id)
    {
        Project memory project = projects[id];
        Treshold memory currentTreshold = projectsTresholds[id][
            project.currentTreshold
        ];

        require(
            !currentTreshold.voteSession.isVotingInSession,
            "Already in Voting Session"
        );

        require(project.active, "Project Inactive");

        require(
            project.currentAmount >= currentTreshold.budget,
            "Treshold not reached yet"
        );

        require(
            project.currentTreshold < project.nbOfTresholds,
            "No more tresholds"
        );

        projectsTresholds[id][project.currentTreshold]
            .voteSession
            .isVotingInSession = true;
    }

    function deliberateVote(uint256 id) private validProjectId(id) {
        Project memory project = projects[id];
        Treshold memory currentTreshold = projectsTresholds[id][
            project.currentTreshold
        ];

        int256 positiveVotes = int256(
            currentTreshold.voteSession.positiveVotes
        );
        int256 negativeVotes = int256(
            currentTreshold.voteSession.negativeVotes
        );
        int256 finalAmount = positiveVotes - negativeVotes;
        require(
            positiveVotes + negativeVotes > 0,
            "Cant deliberate without votes"
        );
        int256 votesPercentage = int256(project.requiredVotePercentage);

        projectsTresholds[id][project.currentTreshold]
            .voteSession
            .isVotingInSession = false;

        if (
            (finalAmount * 10000) / (positiveVotes + negativeVotes) >
            votesPercentage
        ) {
            projects[id].currentTreshold++;

            addWithdrawalAmount(
                project.owner,
                currentTreshold.budget,
                project.exchangeTokenAddress
            );
        } else {
            resetVoteSession(id);
        }
    }

    //cancel vote and stay on current treshold
    function resetVoteSession(uint256 id) private validProjectId(id) {
        Project memory project = projects[id];
        Treshold memory currentTreshold = projectsTresholds[id][
            project.currentTreshold
        ];

        currentTreshold.voteSession.positiveVotes = 0;
        currentTreshold.voteSession.negativeVotes = 0;
        currentTreshold.voteSession.isVotingInSession = false;
        projectsTresholds[id][project.currentTreshold] = currentTreshold;

        for (
            uint256 i = 0;
            i < voterArrayForTreshold[id][project.currentTreshold].length;
            i++
        ) {
            address voter = voterArrayForTreshold[id][project.currentTreshold][
                i
            ];
            tresholdVoteFromAddress[voter][id][project.currentTreshold] = false;
        }

        delete voterArrayForTreshold[id][project.currentTreshold];
    }

    function addWithdrawalAmount(
        address owner,
        uint256 amount,
        address exchangeTokenAddress
    ) private {
        availableWithdrawals[owner][exchangeTokenAddress] += amount;
    }
}
