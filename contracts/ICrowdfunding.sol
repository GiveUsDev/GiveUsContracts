// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title A Crowdfunding Contract
 * @author Ludovic Domingues
 * @notice Contract used for Looting Plateform
 */
interface ICrowdfunding {
    error InvalidProjectId();
    error InvalidThresholdId();
    error TokenNotSupported();
    error ZeroThresholds();
    error ZeroAddress();
    error ZeroRequiredAmount();
    error ZeroRequiredVotePercentage();
    error ZeroAmount();
    error ZeroVoteCooldown();
    error ProjectNotActive();
    error AmountTooSmall();
    error AllowanceNotApproved();
    error TransferFailed();
    error AlreadyInVotingSession();
    error NotInVotingSession();
    error NotADonator();
    error CanOnlyVoteOnce();
    error NoFundsToWithdraw();
    error CantGoAbove10000();
    error ThresholdNotReached();
    error NoMoreThresholds();
    error CantDeliberateWithoutVotes();
    error InvalidUintAsBool();
    error NotProjectOwner();
    error DifferentExchangeToken();
    error CantWithdrawToSameProject();
    error VoteCooldownNotOver();
    error NoFeesToWithdraw();
    error IncorrectVotePercentage();

    /**
     * @notice Event emitted whenever a new project is created
     * @param projectID The id of the project
     * @param owner The owner of said project
     * @param projectName The name of the project
     */
    event ProjectCreated(uint256 indexed projectID, address indexed owner, string projectName);

    /**
     * @notice Event emitted whenever a project receives a new donation
     * @param donatorAddress The donor's address
     * @param projectId The id of the project
     * @param donationAmount The amount donated in wei
     */
    event DonatedToProject(
        address indexed donatorAddress,
        uint256 indexed projectId,
        uint256 indexed donationAmount
    );

    /**
     * @notice Event emitted whenever a project owner withdraws its funds
     * @param projectOwnerAddress The project owner's address
     * @param exchangeTokenAddress The address of the IERC20 contract
     * @param amountToWithdraw The amount withdrawn in wei
     */
    event WithdrewFunds(
        address indexed projectOwnerAddress,
        uint256 indexed projectId,
        address indexed exchangeTokenAddress,
        uint256 amountToWithdraw
    );

    /**
     * @notice Event emitted whenever a project owner withdraws its funds
     * @param tokenAddress The address of the IERC20 contract
     */
    event NewSupportedTokenAdded(address indexed tokenAddress);

    /**
     * @notice Event emitted whenever an admin changes the Donation Fee
     * @param projectId The project's ID
     * @param newFee The new donationFee amount
     */
    event DonationFeeUpdated(uint256 indexed projectId, uint16 indexed newFee);

    /**
     * @notice Event emitted whenever a project is deactivated
     * @param projectId The project's ID
     * @param newStatus The new status of the project
     */
    event ProjectStatusUpdated(uint256 indexed projectId, uint256 indexed newStatus);

    event ProjectVoteCooldownUpdated(uint256 indexed projectId, uint256 indexed newCooldown);

    event VoteSessionReset(
        uint256 indexed projectId,
        uint256 indexed projectThreshold,
        uint256 indexed currentCooldown
    );

    event WithdrewFees(
        address indexed withdrawer,
        address indexed tokenWithdrawn,
        uint256 indexed amountWithdrawn
    );

    struct Threshold {
        uint256 budget;
        VoteSession voteSession;
    }

    struct VoteSession {
        uint256 isVotingInSession;
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
        uint256 voteCooldown;
        uint16 donationFee;
    }

    /**
     * @notice Struct used to create a new project
     */
    struct Project {
        uint256 isActive;
        address owner;
        address exchangeTokenAddress;
        string name;
        string assoName;
        string description;
        uint256 requiredAmount;
        uint256 currentAmount;
        uint256 availableToWithdraw;
        uint256 amountWithdrawn;
        uint256 currentThreshold;
        uint256 nbOfThresholds;
        uint256 requiredVotePercentage; // must be in basis points like 1% = 100 / 100% = 10000 / 0.01% = 1
        uint256 voteCooldown;
        uint256 currentVoteCooldown;
        uint16 donationFee;
    }

    /**
     * @notice Function used to Create a new Project
     * @param projectData Data used to create project
     * @param thresholds Array of threshold for the project
     */
    function createProject(
        ProjectData calldata projectData,
        Threshold[] calldata thresholds
    ) external;

    /**
     * @notice Function returning if a user is a donator or not
     * @param user user address
     * @param id project id
     * @return uint boolean, is user a donator
     */
    function isDonator(address user, uint256 id) external view returns (uint);

    /**
     * @notice Function that checks if token is supported by the contract as an exchange token
     * @param token address of the token you want to check
     * @return uint boolean, is token supported
     */
    function isTokenSupported(address token) external view returns (uint);

    /**
     * @notice Function that returns the project data of a given projectId
     * @param projectId ID of the project
     * @return Project the data for the given project
     */
    function getProject(
        uint256 projectId
    ) external view returns (Project memory);

    /**
     * @notice Function that returns the project threshold of a given projectId and thresholdId
     * @param projectId ID of the project
     * @param thresholdId ID of the threshold
     * @return Threshold the threshold for the given projectId && thresholdId
     */
    function getProjectThresholds(
        uint256 projectId,
        uint256 thresholdId
    ) external view returns (Threshold memory);

    /**
     * @notice Function that returns donated amount from a donatorAddress to a project
     * @param donatorAddress address of the donator
     * @param projectId ID of the project
     * @return uint donated amount
     */
    function getUserDonations(
        address donatorAddress,
        uint256 projectId
    ) external view returns (uint256);

    /**
     * @notice Function that returns if a donator has voted on a threshold
     * @param voterAddress address of the donator/voter
     * @param projectId ID of the project
     * @param thresholdId ID of the threshold
     * @return uint boolean, has voted ?
     */
    function getThresholdVoteFromAddress(
        address voterAddress,
        uint256 projectId,
        uint256 thresholdId
    ) external view returns (uint);

    function getFeesAvailableToWithdraw(
        address tokenAddress
    ) external view returns (uint256);

    /**
     * @notice Donate amount of tokens to project id
     * @param projectId ID of the project
     * @param amount amount to donate
     */
    function donateToProject(uint256 projectId, uint256 amount) external;

    /**
     * @notice Function that starts a vote session for a threshold
     * @param id ID of the project
     */
    function endThresholdVoting(uint256 id) external;

    /**
     * @notice Function that allows a donator to vote for the current threshold of a project
     * @param id ID of the project
     * @param vote true for positive vote, false for negative vote
     */
    function voteForThreshold(uint256 id, uint vote) external;

    /**
     * @notice Function that allows a project owner to withdraw his funds
     */
    function withdrawFunds(uint256 projectId) external;

    /**
     * @notice Function that adds a new supported token
     * @param tokenAddress Address of the ERC20 token
     */
    function addNewSupportedToken(address tokenAddress) external;

    /**
     * @notice Function that sets the donation fee for a project
     * @param projectId ID of the project
     * @param newFee New fee to set
     */
    function setDonationFee(uint256 projectId, uint16 newFee) external;

    /**
     * @notice Function that sets the project status
     * @param projectId ID of the project
     * @param newStatus New status to set
     */
    function updateProjectStatus(uint256 projectId, uint newStatus) external;

    function updateProjectVoteCooldown(
        uint256 projectId,
        uint256 newCooldown
    ) external;

    function withdrawFundsToOtherProject(
        uint256 fromProjectID,
        uint256 toProjectID
    ) external;

    function withdrawFees(address tokenAddress) external;
}
