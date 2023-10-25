// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title A Crowdfunding Contract
 * @author Ludovic Domingues
 * @notice Contract used for Looting Plateform
 */
interface ICrowdfunding {
    /**
     * @notice Custom error messages
     */
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
    error NotInVotingSession();
    error NotADonator();
    error CanOnlyVoteOnce();
    error NoFundsToWithdraw();
    error CantGoAbove10000();
    error CantDeliberateWithoutVotes();
    error NotProjectOwner();
    error DifferentExchangeToken();
    error CantWithdrawToSameProject();
    error NoFeesToWithdraw();

    /**
     * @notice Event emitted whenever a new project is created
     * @param projectID The id of the project
     * @param owner The owner of said project
     * @param projectName The name of the project
     */
    event ProjectCreated(
        uint256 indexed projectID,
        address indexed owner,
        string projectName
    );

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
     * @param projectId The id of the project
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
     * @notice Event emitted whenever new is added to the list of supported tokens
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
     * @notice Event emitted whenever a project's status is updated (active/inactive)
     * @param projectId The project's ID
     * @param newStatus The new status of the project
     */
    event ProjectStatusUpdated(
        uint256 indexed projectId,
        bool indexed newStatus
    );

    /**
     * @notice Event emitted whenever a project's vote cooldown is updated
     * @param projectId The project's ID
     * @param newCooldown The new cooldown for the project
     */
    event ProjectVoteCooldownUpdated(
        uint256 indexed projectId,
        uint256 indexed newCooldown
    );

    /**
     * @notice Event emitted whenever a project's current vote session is reset because the result was negative
     * @param projectId The project's ID
     * @param projectThreshold The treshold for the project's vote session
     * @param currentCooldown The cooldown for the project's vote session
     */
    event VoteSessionReset(
        uint256 indexed projectId,
        uint256 indexed projectThreshold,
        uint256 indexed currentCooldown
    );

    /**
     * @notice Event emitted whenever an admin withdraws the fees gathered from the contract
     * @param withdrawer The admin's address
     * @param tokenWithdrawn The ERC20 token's address that was withdrawn
     * @param amountWithdrawn The amount withdrawn in wei
     */
    event WithdrewFees(
        address indexed withdrawer,
        address indexed tokenWithdrawn,
        uint256 indexed amountWithdrawn
    );

    /**
     * @notice Event emitted whenever a project's vote session is started
     * @param projectId The project's ID
     * @param projectThreshold The treshold for the project's vote session
     */
    event VoteSessionStarted(
        uint256 indexed projectId,
        uint256 indexed projectThreshold
    );

    /**
     * @notice Struct used to store a threshold
     * @param budget The amount of wei required to reach the threshold
     * @param voteSession The vote session for the threshold
     */
    struct Threshold {
        uint256 budget;
        VoteSession voteSession;
    }

    /**
     * @notice Struct used to store a vote session
     * @param isVotingInSession Boolean to know if a vote session is in session
     * @param positiveVotes The amount of positive votes
     * @param negativeVotes The amount of negative votes
     */
    struct VoteSession {
        bool isVotingInSession;
        uint256 positiveVotes;
        uint256 negativeVotes;
    }

    /**
     * @notice Data Struct used to create a new project
     * @param owner The address of the owner of the project
     * @param exchangeTokenAddress The address of the IERC20 contract used for the donations
     * @param name The name of the project
     * @param assoName The name of the association
     * @param description The description of the project
     * @param requiredAmount The amount of wei required to reach the goal
     * @param requiredVotePercentage The percentage of votes required to validate a vote session
     * @param voteCooldown The cooldown between two vote sessions if the previous one was negative
     * @param donationFee The fee taken on each donation
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
     * @dev Uses ProjectData struct
     * @param isActive Boolean to know if the project is active
     * @param owner The address of the owner of the project
     * @param exchangeTokenAddress The address of the IERC20 contract used for the donations
     * @param name The name of the project
     * @param assoName The name of the association
     * @param description The description of the project
     * @param requiredAmount The amount of wei required to reach the goal
     * @param currentAmount The current amount of wei donated to the project
     * @param availableToWithdraw The amount of wei available to withdraw
     * @param amountWithdrawn The amount of wei already withdrawn
     * @param currentThreshold The current threshold for the project
     * @param nbOfThresholds The number of thresholds for the project
     * @param requiredVotePercentage The percentage of votes required to validate a vote session
     * @param voteCooldown The cooldown between two vote sessions if the previous one was negative
     * @param currentVoteCooldown The current cooldown for the project
     * @param donationFee The fee taken on each donation
     */
    struct Project {
        bool isActive;
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
     * @param userAddress The User's address
     * @param projectId The Project's ID
     * @return boolean, is user a donator
     */
    function isDonator(
        address userAddress,
        uint256 projectId
    ) external view returns (bool);

    /**
     * @notice Function that checks if a token is supported by the contract as an exchange token
     * @param tokenAddress Address of the token you want to check
     * @return boolean, Is token supported
     */
    function isTokenSupported(
        address tokenAddress
    ) external view returns (bool);

    /**
     * @notice Function that returns the project data of a given projectId
     * @param projectId ID of the project
     * @return Project The data for the given project
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
     * @notice Function that returns the amount donated from a donatorAddress in a given project
     * @param donatorAddress address of the donator
     * @param projectId ID of the project
     * @return uint Donated amount
     */
    function getUserDonations(
        address donatorAddress,
        uint256 projectId
    ) external view returns (uint256);

    /**
     * @notice Function that returns if a donator has voted on a threshold
     * @param voterAddress Address of the donator/voter
     * @param projectId ID of the project
     * @param thresholdId ID of the threshold
     * @return boolean, Has voted ?
     */
    function getThresholdVoteFromAddress(
        address voterAddress,
        uint256 projectId,
        uint256 thresholdId
    ) external view returns (bool);

    /**
     * @notice Function that returns the amount of fees available to withdraw for a given ERC20 address
     * @param tokenAddress Address of the ERC20 token
     * @return uint Amount of available fees to withdraw
     */
    function getFeesAvailableToWithdraw(
        address tokenAddress
    ) external view returns (uint256);

    /**
     * @notice Donates tokens to a project
     * @param projectId ID of the project
     * @param amount Amount to donate
     */
    function donateToProject(uint256 projectId, uint256 amount) external;

    /**
     * @notice Function that ends the voting period of a given project
     * @param projectId ID of the project
     */
    function endThresholdVoting(uint256 projectId) external;

    /**
     * @notice Function that allows a donator to vote for the current threshold of a project he donated to
     * @param projectId ID of the project
     * @param vote true for positive vote, false for negative vote
     */
    function voteForThreshold(uint256 projectId, bool vote) external;

    /**
     * @notice Function that allows a project owner to withdraw the funds unlocked on his project
     * @param projectId The projet's ID
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
     * @notice Function that sets the project status of a given project
     * @param projectId ID of the project
     * @param newStatus New status to set
     */
    function updateProjectStatus(uint256 projectId, bool newStatus) external;

    /**
     * @notice Function that sets the VoteCooldown of a given project
     * @param projectId ID of the project
     * @param newCooldown New cooldown amount to set
     */
    function updateProjectVoteCooldown(
        uint256 projectId,
        uint256 newCooldown
    ) external;

    /**
     * @notice Function used to move funds beetween projects (Only used in case of emergency)
     * @param fromProjectID ID of the project we withdraw the funds from
     * @param toProjectID ID of the project we send the funds to
     */
    function withdrawFundsToOtherProject(
        uint256 fromProjectID,
        uint256 toProjectID
    ) external;

    /**
     * @notice Function that allows an Admin to withdraw fees from the contract
     * @param tokenAddress The adress of the ERC20 token we want to withdraw
     */
    function withdrawFees(address tokenAddress) external;
}
