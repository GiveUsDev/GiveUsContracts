// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ICrowdfunding} from "./ICrowdfunding.sol";

/**
 * @title Crowdfunding.sol
 * @author Ludovic Domingues
 * @notice GiveUs Smart contract responsible for the crowdfunding logic
 */
contract Crowdfunding is
    ICrowdfunding,
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev The following constants are used by AccessControl to check authorisations.
     */
    /// @notice The PAUSER_ROLE allows an account to pause/unpause the contract.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /// @notice The UPDATER_ROLE allows an account to create/update/delete projects.
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    /// @notice The WITHDRAWER_ROLE allows an account to withdraw the fees funds from the contract.
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    /// @dev  Counter used for project id
    CountersUpgradeable.Counter private idCounter;

    /// @dev  Mapping used to store if a token is supported (TokenAddress => bool) //TODO: convert to boolean
    mapping(address => uint256) private supportedTokens; 
    /// @dev  Mapping used to store the projects and their struct data (ProjectId => Project)
    mapping(uint256 => Project) private projects;
    /// @dev  Mapping used to store the project (ProjetId => ThresholdId => Threshold)
    /// @dev Each threshold has its own budget like [10,20,30] this means the total budget is 10+20+30
    mapping(uint256 => mapping(uint256 => Threshold))
        private projectsThresholds;
    /// @dev Mapping used to store the donations Amounts (User Address => ProjectId => DonationAmount)
    mapping(address => mapping(uint256 => uint256)) private userDonations;
    /// @dev Mapping used to store the vote made by address to specific threshold (User Address => ProjectId => ThresholdId => bool)
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) //TODO: convert to boolean
        private thresholdVoteFromAddress;
    /// @dev Mapping used to store all User Addresses that voted for specific threshold (ProjectId => ThresholdId => User Addresses[])
    mapping(uint256 => mapping(uint256 => address[]))
        private voterArrayForThreshold;

    /// @dev Mapping used to store the fees taken and can be withdrawn by address (ERC20 Token Address => Amount)
    mapping(address => uint256) private availableFees;

    /// @dev Modifier used to check if id ProjectId is valid
    /// @param id ProjectId
    modifier validProjectId(uint256 id) {
        if (idCounter.current() <= id) {
            revert InvalidProjectId();
        }
        _;
    }

    /// @dev Modifier used to check if thresholdId of projectId is valid
    /// @param projectId ProjectId
    ///@param thresholdId Threshold Id of given Project Id
    modifier validThresholdId(uint256 projectId, uint256 thresholdId) {
        Project memory project = projects[projectId];
        if (project.nbOfThresholds <= thresholdId) {
            revert InvalidThresholdId();
        }
        _;
    }

    /// @dev Modifier used to check if exchangeTokenAddress is supported
    /// @param exchangeTokenAddress Address of the ERC20 Token
    modifier supportedToken(address exchangeTokenAddress) {
        if (isTokenSupported(exchangeTokenAddress) == 0) {
            revert TokenNotSupported();
        }
        _;
    }

    /**
     * @notice Initializer used to set the default roles and initialise Access Control and Pausable
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `PAUSER_ROLE`, `UPDATER_ROLE` and `WITHDRAWER_ROLE` to the msg.sender
     */
    function initialize() external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
        _grantRole(WITHDRAWER_ROLE, msg.sender);
        __AccessControl_init();
        __Pausable_init();
    }

    /**
     * @notice Function used to Create a new Project
     * @param projectData Data used to create project
     * @param thresholds Array of threshold for the project
     * @dev Can only be called when the contract is not Paused
     */
    function createProject(
        ProjectData calldata projectData,
        Threshold[] calldata thresholds
    )
        external
        virtual
        override
        onlyRole(UPDATER_ROLE)
        whenNotPaused
        supportedToken(projectData.exchangeTokenAddress)
    {
        if (thresholds.length == 0) {
            revert ZeroThresholds();
        }
        if (projectData.requiredAmount == 0) {
            revert ZeroRequiredAmount();
        }
        if (projectData.voteCooldown == 0) {
            revert ZeroVoteCooldown();
        }
        if (projectData.requiredVotePercentage == 0) {
            revert ZeroRequiredVotePercentage();
        }
        if (projectData.requiredVotePercentage > 10000) {
            revert CantGoAbove10000();
        }
        if (projectData.donationFee > 10000) {
            revert CantGoAbove10000();
        }
        if (projectData.owner == address(0)) {
            revert ZeroAddress();
        }

        uint256 currentId = idCounter.current();
        projects[currentId] = Project(
            1,
            projectData.owner,
            projectData.exchangeTokenAddress,
            projectData.name,
            projectData.assoName,
            projectData.description,
            projectData.requiredAmount,
            0,
            0,
            0,
            0,
            thresholds.length,
            projectData.requiredVotePercentage,
            projectData.voteCooldown,
            0,
            projectData.donationFee
        );

        for (uint256 i; i < thresholds.length; ) {
            projectsThresholds[currentId][i] = thresholds[i];
            unchecked {
                ++i;
            }
        }

        idCounter.increment();

        emit ProjectCreated(currentId, projectData.owner, projectData.name);
    }

    /**
     * @notice Function that returns the project data of a given projectId
     * @param projectId ID of the project
     * @return Project The data for the given project
     */
    function getProject(
        uint256 projectId
    )
        external
        view
        virtual
        override
        validProjectId(projectId)
        returns (Project memory)
    {
        return projects[projectId];
    }

    /**
     * @notice Function that returns the project threshold of a given projectId and thresholdId
     * @param projectId ID of the project
     * @param thresholdId ID of the threshold
     * @return Threshold the threshold for the given projectId && thresholdId
     */
    function getProjectThresholds(
        uint256 projectId,
        uint256 thresholdId
    )
        external
        view
        virtual
        override
        validProjectId(projectId)
        validThresholdId(projectId, thresholdId)
        returns (Threshold memory)
    {
        return projectsThresholds[projectId][thresholdId];
    }

    /**
     * @notice Function that returns the amount donated from a donatorAddress in a given project
     * @param donatorAddress address of the donator
     * @param projectId ID of the project
     * @return uint Donated amount
     */
    function getUserDonations(
        address donatorAddress,
        uint256 projectId
    )
        external
        view
        virtual
        override
        validProjectId(projectId)
        returns (uint256)
    {
        return userDonations[donatorAddress][projectId];
    }

    /**
     * @notice Function that returns if a donator has voted on a threshold
     * @param voterAddress Address of the donator/voter
     * @param projectId ID of the project
     * @param thresholdId ID of the threshold
     * @return uint boolean, Has voted ? //TODO: convert to boolean
     */
    function getThresholdVoteFromAddress(
        address voterAddress,
        uint256 projectId,
        uint256 thresholdId
    )
        external
        view
        virtual
        override
        validProjectId(projectId)
        validThresholdId(projectId, thresholdId)
        returns (uint256)
    {
        return thresholdVoteFromAddress[voterAddress][projectId][thresholdId];
    }


    /**
     * @notice Function that returns the amount of fees available to withdraw for a given ERC20 address
     * @param tokenAddress Address of the ERC20 token
     * @return uint Amount of available fees to withdraw
     */
    function getFeesAvailableToWithdraw(
        address tokenAddress
    ) external view virtual override returns (uint256) {
        return availableFees[tokenAddress];
    }

    /**
     * @notice Triggers Paused state
     * @dev Can only be called by the PAUSER_ROLE and when not already paused
     */
    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    /**
     * @notice Returns to Normal state from Paused State
     * @dev Can only be called by the PAUSER_ROLE and when the contract is in the Paused State
     */
    function unpause() external onlyRole(PAUSER_ROLE) whenPaused {
        _unpause();
    }

    /**
     * @notice Donates tokens to a project
     * @notice The tokens given are the ones used by the project
     * @param projectId ID of the project
     * @param amount Amount to donate
     * @dev Can only be called when the contract is not Paused
     */
    function donateToProject(
        uint256 projectId,
        uint256 amount
    ) external virtual override whenNotPaused validProjectId(projectId) {
        if (amount == 0) {
            revert ZeroAmount();
        }
        Project memory project = projects[projectId];

        if (project.isActive == 0) {
            revert ProjectNotActive();
        }

        if ((amount / 10000) * 10000 != amount) {
            revert AmountTooSmall();
        }

        address tokenSupported = project.exchangeTokenAddress;

        if (
            IERC20Upgradeable(tokenSupported).allowance(
                msg.sender,
                address(this)
            ) < amount
        ) {
            revert AllowanceNotApproved();
        }

        uint256 transactionFee = (amount * project.donationFee) / 10000;
        availableFees[tokenSupported] += transactionFee;

        uint256 donationAmount = amount - transactionFee;

        //Somehow the second one is more gas efficient written this way but not the first one
        userDonations[msg.sender][projectId] += donationAmount;
        projects[projectId].currentAmount =
            projects[projectId].currentAmount +
            donationAmount;

        project = projects[projectId];
        Threshold memory currentThreshold = projectsThresholds[projectId][
            project.currentThreshold
        ];

        CheckAndStartThresholdVoting(projectId);

        IERC20Upgradeable(tokenSupported).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit DonatedToProject(msg.sender, projectId, donationAmount);
    }

    /**
     * @notice Function that ends the voting period of a given project
     * @param projectId ID of the project
     * @dev Can only be called when the contract is not Paused
     * @dev Can only be called by an address with the UPDATER_ROLE role
     */
    function endThresholdVoting(
        uint256 projectId
    )
        external
        virtual
        override
        onlyRole(UPDATER_ROLE)
        whenNotPaused
        validProjectId(projectId)
    {
        Project memory project = projects[projectId];
        Threshold memory currentThreshold = projectsThresholds[projectId][
            project.currentThreshold
        ];
        if (currentThreshold.voteSession.isVotingInSession == 0) {
            revert NotInVotingSession();
        }

        projectsThresholds[projectId][project.currentThreshold]
            .voteSession
            .isVotingInSession = 0;

        deliberateVote(projectId);
    }

    /**
     * @notice Function that allows a donator to vote for the current threshold of a project he donated to
     * @param projectId ID of the project
     * @param vote true for positive vote, false for negative vote //TODO: convert to boolean
     * @dev Can only be called when the contract is not Paused
     */
    function voteForThreshold(
        uint256 projectId,
        uint256 vote
    ) external virtual override whenNotPaused validProjectId(projectId) {
        if (vote > 1) {
            revert InvalidUintAsBool();
        }
        if (isDonator(msg.sender, projectId) == 0) {
            revert NotADonator();
        }

        Project memory project = projects[projectId];
        Threshold memory currentThreshold = projectsThresholds[projectId][
            project.currentThreshold
        ];

        if (currentThreshold.voteSession.isVotingInSession == 0) {
            revert NotInVotingSession();
        }

        if (
            thresholdVoteFromAddress[msg.sender][projectId][
                project.currentThreshold
            ] == 1
        ) {
            revert CanOnlyVoteOnce();
        }

        VoteSession memory vs = currentThreshold.voteSession;
        vote == 1 ? vs.positiveVotes++ : vs.negativeVotes++;

        projectsThresholds[projectId][project.currentThreshold].voteSession = vs;
        thresholdVoteFromAddress[msg.sender][projectId][project.currentThreshold] = 1;
        voterArrayForThreshold[projectId][project.currentThreshold].push(msg.sender);
    }

    /**
     * @notice Function that allows a project owner to withdraw the funds unlocked on his project
     * @dev Can only be called when the contract is not Paused
     * @param projectId The projet's ID
     */
    function withdrawFunds(
        uint256 projectId
    ) external virtual override whenNotPaused validProjectId(projectId) {
        Project memory project = projects[projectId];
        if (project.owner != msg.sender) {
            revert NotProjectOwner();
        }

        uint256 amountToWithdraw = project.availableToWithdraw;

        if (amountToWithdraw == 0) {
            revert NoFundsToWithdraw();
        }

        address exchangeTokenAddress = project.exchangeTokenAddress;

        project.availableToWithdraw = 0;
        project.amountWithdrawn += amountToWithdraw;

        projects[projectId] = project;

        IERC20Upgradeable(exchangeTokenAddress).safeTransfer(
            msg.sender,
            amountToWithdraw
        );

        emit WithdrewFunds(
            msg.sender,
            projectId,
            exchangeTokenAddress,
            amountToWithdraw
        );
    }

    /**
     * @notice Function that allows an Admin to withdraw fees from the contract
     * @dev Can only be called when the contract is not Paused
     * @dev Can only be called by a user with the WITHDRAWER_ROLE role
     * @param tokenAddress The adress of the ERC20 token we want to withdraw
     */
    function withdrawFees(
        address tokenAddress
    ) external virtual override onlyRole(WITHDRAWER_ROLE) whenNotPaused {
        if(tokenAddress == address(0)){
            revert ZeroAddress();
        }

        uint256 amountToWithdraw = availableFees[tokenAddress];
        
        if (amountToWithdraw == 0) {
            revert NoFeesToWithdraw();
        }

        availableFees[tokenAddress] = 0;

        IERC20Upgradeable(tokenAddress).safeTransfer(
            msg.sender,
            amountToWithdraw
        );

        emit WithdrewFees(msg.sender, tokenAddress, amountToWithdraw);
    }

    /**
     * @notice Function that adds a new supported token
     * @param tokenAddress Address of the ERC20 token
     * @dev Can only be called by a user with the UPDATER_ROLE role
     */
    function addNewSupportedToken(
        address tokenAddress
    ) external virtual override onlyRole(UPDATER_ROLE) {
        if (tokenAddress == address(0)) {
            revert ZeroAddress();
        }
        supportedTokens[tokenAddress] = 1;
        emit NewSupportedTokenAdded(tokenAddress);
    }

    /**
     * @notice Function that sets the donation fee for a project
     * @param projectId ID of the project
     * @param newFee New fee to set
     * @dev Can only be called by a user with the UPDATER_ROLE role
     */
    function setDonationFee(
        uint256 projectId,
        uint16 newFee
    )
        external
        virtual
        override
        onlyRole(UPDATER_ROLE)
        validProjectId(projectId)
    {
        if (newFee > 10000) {
            revert CantGoAbove10000();
        }
        projects[projectId].donationFee = newFee;
        emit DonationFeeUpdated(projectId, newFee);
    }

    /**
     * @notice Function that sets the project status of a given project
     * @param projectId ID of the project
     * @param newStatus New status to set
     * @dev Can only be called by a user with the UPDATER_ROLE role
     */
    function updateProjectStatus(
        uint256 projectId,
        uint256 newStatus
    )
        external
        virtual
        override
        onlyRole(UPDATER_ROLE)
        validProjectId(projectId)
    {
        if (newStatus > 1) {
            revert InvalidUintAsBool();
        }

        projects[projectId].isActive = newStatus;
        emit ProjectStatusUpdated(projectId, newStatus);
    }

    /**
     * @notice Function that sets the VoteCooldown of a given project
     * @param projectId ID of the project
     * @param newCooldown New cooldown amount to set
     * @dev Can only be called by a user with the UPDATER_ROLE role
     */
    function updateProjectVoteCooldown(
        uint256 projectId,
        uint256 newCooldown
    )
        external
        virtual
        override
        onlyRole(UPDATER_ROLE)
        validProjectId(projectId)
    {
        projects[projectId].voteCooldown = newCooldown;
        emit ProjectVoteCooldownUpdated(projectId, newCooldown);
    }

    /**
     * @notice Function used to move funds beetween projects (Only used in case of emergency)
     * @param fromProjectID ID of the project we withdraw the funds from
     * @param toProjectID ID of the project we send the funds to
     * @dev Can only be called by a user with the UPDATER_ROLE role
     */
    function withdrawFundsToOtherProject(
        uint256 fromProjectID,
        uint256 toProjectID
    )
        external
        virtual
        override
        onlyRole(UPDATER_ROLE)
        validProjectId(fromProjectID)
        validProjectId(toProjectID)
    {
        if (fromProjectID == toProjectID) {
            revert CantWithdrawToSameProject();
        }

        Project memory fromProject = projects[fromProjectID];
        Project memory toProject = projects[toProjectID];

        if (toProject.isActive == 0) {
            revert ProjectNotActive();
        }

        uint256 availableFunds = fromProject.currentAmount -
            fromProject.amountWithdrawn;

        if (availableFunds == 0) {
            revert NoFundsToWithdraw();
        }

        if (
            fromProject.exchangeTokenAddress != toProject.exchangeTokenAddress
        ) {
            revert DifferentExchangeToken();
        }

        //If the project is still active we deactivate it
        //This function is only used in a case of emergency
        //so logically we should deactivate the project
        if (fromProject.isActive == 1) {
            fromProject.isActive = 0;
        }

        fromProject.currentAmount = fromProject.currentAmount - availableFunds;
        fromProject.availableToWithdraw = 0;
        toProject.currentAmount = toProject.currentAmount + availableFunds;

        projects[fromProjectID] = fromProject;
        projects[toProjectID] = toProject;
    }

    /**
     * @notice Function returning if a user is a donator or not
     * @param userAddress The User's address
     * @param projectId The Project's ID
     * @return uint boolean, is user a donator //TODO: replace with boolean
     */
    function isDonator(
        address userAddress,
        uint256 projectId
    ) public view virtual override validProjectId(projectId) returns (uint256) {
        return userDonations[userAddress][projectId] != 0 ? 1 : 0;
    }

    /**
     * @notice Function that checks if a token is supported by the contract as an exchange token
     * @param tokenAddress Address of the token you want to check
     * @return uint boolean, Is token supported //TODO: replace with boolean
     */
    function isTokenSupported(address tokenAddress) public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return 0;
        }
        return supportedTokens[tokenAddress];
    }


    /**
     * @dev Function that checks if a threshold is reached for a given project and starts a vote if it is
     * @param projectId The project's ID
     */
    function CheckAndStartThresholdVoting(uint256 projectId) private {
        Project memory project = projects[projectId];
        Threshold memory currentThreshold = projectsThresholds[projectId][
            project.currentThreshold
        ];

        if (
            project.currentAmount >= currentThreshold.budget &&
            currentThreshold.voteSession.isVotingInSession == 0 &&
            project.currentThreshold < project.nbOfThresholds &&
            project.currentVoteCooldown <= block.timestamp
        ) {
            projectsThresholds[projectId][project.currentThreshold]
                .voteSession
                .isVotingInSession = 1;
        }
    }

    /**
     * @dev Function used to deliberate of a vote's result
     * @param projectId The project's ID
     */
    function deliberateVote(uint256 projectId) private {
        Project memory project = projects[projectId];
        Threshold memory currentThreshold = projectsThresholds[projectId][
            project.currentThreshold
        ];

        int256 positiveVotes = int256(
            currentThreshold.voteSession.positiveVotes
        );
        int256 negativeVotes = int256(
            currentThreshold.voteSession.negativeVotes
        );

        if (positiveVotes + negativeVotes == 0) {
            revert CantDeliberateWithoutVotes();
        }

        int256 votesPercentage = int256(project.requiredVotePercentage);

        projectsThresholds[projectId][project.currentThreshold]
            .voteSession
            .isVotingInSession = 0;

        if (
            (positiveVotes * 10000) / (positiveVotes + negativeVotes) >
            votesPercentage
        ) {
            project.availableToWithdraw += currentThreshold.budget;
            project.currentThreshold++;

            //updating global variables
            projects[projectId] = project;

            if (project.currentThreshold < project.nbOfThresholds) {
                currentThreshold = projectsThresholds[projectId][
                    project.currentThreshold
                ];

                //check if we have enough funds to start next vote
                CheckAndStartThresholdVoting(projectId);
            }
        } else {
            //reset vote session if the result is negative
            resetVoteSession(projectId);
        }
    }

    /**
     * @dev Function used to reset a vote session and put it on cooldown
     * @param projectId The project's ID
     */
    function resetVoteSession(uint256 projectId) private {
        Project memory project = projects[projectId];
        Threshold memory currentThreshold = projectsThresholds[projectId][
            project.currentThreshold
        ];

        currentThreshold.voteSession.positiveVotes = 0;
        currentThreshold.voteSession.negativeVotes = 0;
        currentThreshold.voteSession.isVotingInSession = 0;
        projectsThresholds[projectId][project.currentThreshold] = currentThreshold;

        address[] memory tempVoterArrayForThreshold = voterArrayForThreshold[
            projectId
        ][project.currentThreshold];
        uint256 length = voterArrayForThreshold[projectId][project.currentThreshold]
            .length;
        address voter;

        for (uint256 i; i < length; ) {
            voter = tempVoterArrayForThreshold[i];
            thresholdVoteFromAddress[voter][projectId][project.currentThreshold] = 0;
            unchecked {
                ++i;
            }
        }

        delete voterArrayForThreshold[projectId][project.currentThreshold];

        uint256 newCooldown = block.timestamp + project.voteCooldown;

        projects[projectId].currentVoteCooldown = newCooldown;

        emit VoteSessionReset(projectId, project.currentThreshold, newCooldown);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}
