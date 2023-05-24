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
 * @title A Crowdfunding Contract
 * @author Ludovic Domingues
 * @notice Contract used for GiveUs Plateform
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
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    CountersUpgradeable.Counter private idCounter;

    mapping(address => uint256) private supportedTokens;
    mapping(uint256 => Project) private projects; //get project by id
    mapping(uint256 => mapping(uint256 => Threshold))
        private projectsThresholds; //get project by id and threshold by id // each threshold has its own budget like [10,20,30] this means the total budget is 10+20+30 //can add alter a function to add new thresholds
    mapping(address => mapping(uint256 => uint256)) private userDonations;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private thresholdVoteFromAddress;
    mapping(uint256 => mapping(uint256 => address[]))
        private voterArrayForThreshold;
    mapping(address => uint256) private availableFees;

    modifier validProjectId(uint256 id) {
        if (idCounter.current() <= id) {
            revert InvalidProjectId();
        }
        _;
    }

    modifier validThresholdId(uint256 projectId, uint256 thresholdId) {
        Project memory project = projects[projectId];
        if (project.nbOfThresholds <= thresholdId) {
            revert InvalidThresholdId();
        }
        _;
    }

    modifier supportedToken(address exchangeTokenAddress) {
        if (isTokenSupported(exchangeTokenAddress) == 0) {
            revert TokenNotSupported();
        }
        _;
    }

    /**
     * @notice Initializer used to set the default roles
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
     * @return Project the data for the given project
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
     * @notice Function that returns donated amount from a donatorAddress to a project
     * @param donatorAddress address of the donator
     * @param projectId ID of the project
     * @return uint donated amount
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
     * @param voterAddress address of the donator/voter
     * @param projectId ID of the project
     * @param thresholdId ID of the threshold
     * @return uint boolean, has voted ?
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

    function getFeesAvailableToWithdraw(
        address tokenAddress
    ) external view virtual override returns (uint256) {
        return availableFees[tokenAddress];
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
     * @notice Function that
     * @param id ID of the project
     */
    function endThresholdVoting(
        uint256 id
    )
        external
        virtual
        override
        onlyRole(UPDATER_ROLE)
        whenNotPaused
        validProjectId(id)
    {
        Project memory project = projects[id];
        Threshold memory currentThreshold = projectsThresholds[id][
            project.currentThreshold
        ];
        if (currentThreshold.voteSession.isVotingInSession == 0) {
            revert NotInVotingSession();
        }

        projectsThresholds[id][project.currentThreshold]
            .voteSession
            .isVotingInSession = 0;

        deliberateVote(id);
    }

    /**
     * @notice Function that allows a donator to vote for the current threshold of a project
     * @param id ID of the project
     * @param vote true for positive vote, false for negative vote
     */
    function voteForThreshold(
        uint256 id,
        uint256 vote
    ) external virtual override whenNotPaused validProjectId(id) {
        if (vote > 1) {
            revert InvalidUintAsBool();
        }
        if (isDonator(msg.sender, id) == 0) {
            revert NotADonator();
        }

        Project memory project = projects[id];
        Threshold memory currentThreshold = projectsThresholds[id][
            project.currentThreshold
        ];

        if (currentThreshold.voteSession.isVotingInSession == 0) {
            revert NotInVotingSession();
        }

        if (
            thresholdVoteFromAddress[msg.sender][id][
                project.currentThreshold
            ] == 1
        ) {
            revert CanOnlyVoteOnce();
        }

        VoteSession memory vs = currentThreshold.voteSession;
        vote == 1 ? vs.positiveVotes++ : vs.negativeVotes++;

        projectsThresholds[id][project.currentThreshold].voteSession = vs;
        thresholdVoteFromAddress[msg.sender][id][project.currentThreshold] = 1;
        voterArrayForThreshold[id][project.currentThreshold].push(msg.sender);
    }

    /**
     * @notice Function that allows a project owner to withdraw his funds
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
     * @notice Function that sets the project status
     * @param projectId ID of the project
     * @param newStatus New status to set
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
     * @param user user address
     * @param id project id
     * @return uint boolean, is user a donator
     */
    function isDonator(
        address user,
        uint256 id
    ) public view virtual override validProjectId(id) returns (uint256) {
        return userDonations[user][id] != 0 ? 1 : 0;
    }

    /**
     * @notice Function that checks if token is supported by the contract as an exchange token
     * @param token address of the token you want to check
     * @return uint boolean, is token supported
     */
    function isTokenSupported(address token) public view returns (uint256) {
        if (token == address(0)) {
            return 0;
        }
        return supportedTokens[token];
    }

    //The ID is always Valid but i still put the modifier just in case
    //The whenNotPaused is always Valid but i still put the modifier just in case
    function CheckAndStartThresholdVoting(uint256 id) private {
        Project memory project = projects[id];
        Threshold memory currentThreshold = projectsThresholds[id][
            project.currentThreshold
        ];

        if (
            project.currentAmount >= currentThreshold.budget &&
            currentThreshold.voteSession.isVotingInSession == 0 &&
            project.currentThreshold < project.nbOfThresholds &&
            project.currentVoteCooldown <= block.timestamp
        ) {
            projectsThresholds[id][project.currentThreshold]
                .voteSession
                .isVotingInSession = 1;
        }
    }

    //The ID is always Valid but i still put the modifier just in case
    //The whenNotPaused is always Valid but i still put the modifier just in case
    function deliberateVote(uint256 id) private {
        Project memory project = projects[id];
        Threshold memory currentThreshold = projectsThresholds[id][
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

        projectsThresholds[id][project.currentThreshold]
            .voteSession
            .isVotingInSession = 0;

        if (
            (positiveVotes * 10000) / (positiveVotes + negativeVotes) >
            votesPercentage
        ) {
            project.availableToWithdraw += currentThreshold.budget;
            project.currentThreshold++;

            //updating global variables
            projects[id] = project;

            if (project.currentThreshold < project.nbOfThresholds) {
                currentThreshold = projectsThresholds[id][
                    project.currentThreshold
                ];

                //check if we have enough funds to start next vote
                CheckAndStartThresholdVoting(id);
            }
        } else {
            resetVoteSession(id);
        }
    }

    //cancel vote and stay on current threshold
    function resetVoteSession(uint256 id) private {
        Project memory project = projects[id];
        Threshold memory currentThreshold = projectsThresholds[id][
            project.currentThreshold
        ];

        currentThreshold.voteSession.positiveVotes = 0;
        currentThreshold.voteSession.negativeVotes = 0;
        currentThreshold.voteSession.isVotingInSession = 0;
        projectsThresholds[id][project.currentThreshold] = currentThreshold;

        address[] memory tempVoterArrayForThreshold = voterArrayForThreshold[
            id
        ][project.currentThreshold];
        uint256 length = voterArrayForThreshold[id][project.currentThreshold]
            .length;
        address voter;

        for (uint256 i; i < length; ) {
            voter = tempVoterArrayForThreshold[i];
            thresholdVoteFromAddress[voter][id][project.currentThreshold] = 0;
            unchecked {
                ++i;
            }
        }

        delete voterArrayForThreshold[id][project.currentThreshold];

        uint256 newCooldown = block.timestamp + project.voteCooldown;

        projects[id].currentVoteCooldown = newCooldown;

        emit VoteSessionReset(id, project.currentThreshold, newCooldown);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}
