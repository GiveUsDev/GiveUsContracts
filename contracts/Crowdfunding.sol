// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Crowdfunding is AccessControl, Pausable {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    struct Donation {
        address donatorAddress;
        uint256 amountDonated;
    }

    struct Treshold {
        uint256 budget;
        VoteSession voteSession;
    }

    struct VoteSession {
        bool isVotingInSession;
        //uint256 numberOfVotes; useless ?
        uint256 positiveVotes;
        uint256 negativeVotes;
    }

    struct ProjectData {
        address owner;
        address exchangeTokenAddress;
        string name;
        string assoName;
        string[] teamMembers;
        string description;
        uint256 requiredAmount;
        uint256 requiredVotePercentage; // must be in integer like 50% = 50 28% = 28
    }

    //TODO support vote
    struct Project {
        bool active;
        address owner;
        address exchangeTokenAddress;
        string name;
        string assoName;
        string[] teamMembers;
        string description;
        uint256 requiredAmount;
        uint256 currentAmount;
        uint256 currentUnlockedAmount;
        uint256 currentTreshold;
        uint256 nbOfTresholds;
        uint256 requiredVotePercentage; // must be in integer like 50% = 50 28% = 28
    }

    address[] public supportedTokens;
    mapping(uint256 => Project) public projects; //get project by id
    mapping(uint256 => mapping(uint256 => Treshold)) public projectsTresholds; //get project by id and treshold by id // each treshold has its own budget like [10,20,30] this means the total budget is 10+20+30 //can add alter a function to add new tresholds
    //mapping from user to project by id to the amount donated
    mapping(address => mapping(uint256 => uint256)) public userDonations;
    //mapping(uint256 => mapping(address => bool)) public donatorsPerProjects;
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        public tresholdVoteFromAddress;

    mapping(address => mapping(address => uint256)) public availableWithdrawals;

    Counters.Counter private idCounter;

    ///DONE
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
    }

    ///DONE
    function CreateProject(
        ProjectData calldata _projectData,
        Treshold[] calldata tresholds
    ) public {
        require(
            IsTokenSupported(_projectData.exchangeTokenAddress),
            "Token not supported"
        );
        require(tresholds.length > 0, "Need at least one Treshold");
        uint256 currentId = idCounter.current();
        projects[currentId] = Project(
            true,
            _projectData.owner,
            _projectData.exchangeTokenAddress,
            _projectData.name,
            _projectData.assoName,
            _projectData.teamMembers,
            _projectData.description,
            _projectData.requiredAmount,
            0,
            0,
            0,
            tresholds.length,
            _projectData.requiredVotePercentage
        );

        for (uint256 i = 0; i < tresholds.length; i++) {
            projectsTresholds[currentId][i] = tresholds[i];
        }

        idCounter.increment();
    }

    //check conditions for project ID and advance to next treshold
    /*function GoToNextTreshold(uint256 id) public {
        Project memory project = projects[id];
        require(msg.sender == project.owner, "You are not allowed");
        require(
            project.currentTreshold < project.tresholds.length + 1,
            "Project Funded"
        );

        //TODO check back on this 
        if (
            project.currentAmount >=
            project.tresholds[project.currentTreshold].budget
        ) {
            UnlockNextTreshold(id);
        }
    }*/

    //DONE
    //Returns if a user is a donator of project id
    function IsDonator(address user, uint256 id) public view returns (bool) {
        return userDonations[user][id] > 0;
    }

    ///DONE
    //TODO dos issue
    //check if token token is supported by the contract as an exchange token
    function IsTokenSupported(address token) public view returns (bool) {
        address[] memory tempSupportedTokens = supportedTokens;

        for (uint256 i = 0; i < tempSupportedTokens.length; i++) {
            if (tempSupportedTokens[i] == token) {
                return true;
            }
        }

        return false;
    }

    ///DONE
    //donate amount amount of tokens to project id
    function DonateToProject(uint256 id, uint256 amount) external {
        require(amount > 0, "Min amount is 1");
        Project memory project = projects[id];
        require(project.active, "Project not Active");
        require(
            project.currentAmount + amount <= project.requiredAmount,
            "Cant go above Donation Goal"
        );

        address tokenSupported = project.exchangeTokenAddress;

        require(
            IERC20(tokenSupported).allowance(msg.sender, address(this)) >=
                amount,
            "Need to approve allowance first"
        );
        IERC20(tokenSupported).transferFrom(msg.sender, address(this), amount);

        userDonations[msg.sender][id] += amount;
        projects[id].currentAmount += amount;
    }

    //DONE
    //Starts the treshold vote of project id
    function StartTresholdVoting(uint256 id) external {
        Project memory project = projects[id];
        Treshold memory currentTreshold = projectsTresholds[id][
            project.currentTreshold
        ];
        require(msg.sender == project.owner, "You are not allowed");
        require(
            !currentTreshold.voteSession.isVotingInSession,
            "Already in Voting Session"
        );
        require(
            project.active &&
                project.currentUnlockedAmount < project.requiredAmount,
            "Project Funded or Inactive"
        );

        require(
            project.currentAmount - project.currentUnlockedAmount >=
                currentTreshold.budget,
            "Treshold not reached yet"
        );

        projectsTresholds[id][project.currentTreshold]
            .voteSession
            .isVotingInSession = true;
    }

    //Ends the treshold vote of project id
    function EndTresholdVoting(uint256 id) external {
        Project memory project = projects[id];
        Treshold memory currentTreshold = projectsTresholds[id][
            project.currentTreshold
        ];
        require(msg.sender == project.owner, "You are not allowed");
        require(
            currentTreshold.voteSession.isVotingInSession,
            "Not in Voting Session"
        );

        projectsTresholds[id][project.currentTreshold]
            .voteSession
            .isVotingInSession = false;

        DeliberateVote(id);
    }

    // Donator votes for current treshold voting session of project id
    function VoteForTreshold(uint256 id, bool vote) external {
        Project memory project = projects[id];
        Treshold memory currentTreshold = projectsTresholds[id][
            project.currentTreshold
        ];
        require(IsDonator(msg.sender, id), "Only Donators can vote");
        require(
            currentTreshold.voteSession.isVotingInSession,
            "Not in Voting Session"
        );

        VoteSession memory vs = currentTreshold.voteSession;
        vote ? vs.positiveVotes++ : vs.negativeVotes++;

        projectsTresholds[id][project.currentTreshold].voteSession = vs;
        tresholdVoteFromAddress[msg.sender][id][project.currentTreshold] = true;
    }

    //TODO Add withdrawer role
    function WithdrawFunds(address exchangeTokenAddress) external {
        uint256 amountToWithdraw = availableWithdrawals[msg.sender][
            exchangeTokenAddress
        ];
        require(amountToWithdraw > 0, "No Funds to withdraw");
        IERC20(exchangeTokenAddress).transfer(msg.sender, amountToWithdraw);
    }

    ///DONE
    function AddNewSupportedToken(address tokenAddress)
        external
        onlyRole(UPDATER_ROLE)
    {
        supportedTokens.push(tokenAddress);
    }

    //Deliberate vote of project id and unlocks next treshold if there is
    function DeliberateVote(uint256 id) private {
        Project memory project = projects[id];
        Treshold memory currentTreshold = projectsTresholds[id][
            project.currentTreshold
        ];

        uint256 positiveVotes = currentTreshold.voteSession.positiveVotes;
        uint256 negativeVotes = currentTreshold.voteSession.negativeVotes;
        require(
            positiveVotes + negativeVotes > 0,
            "Cant deliberate without votes"
        );
        uint256 votesPercentage = project.requiredVotePercentage;

        projectsTresholds[id][project.currentTreshold]
            .voteSession
            .isVotingInSession = false;

        if (negativeVotes > 0) {
            if (
                (positiveVotes * 10000) / (negativeVotes * 100) >
                votesPercentage
            ) {
                if (project.currentTreshold < project.nbOfTresholds - 1) {
                    projects[id].currentTreshold++;
                } else {
                    projects[id].active = false;
                }

                AddWithdrawalAmount(
                    project.owner,
                    currentTreshold.budget,
                    project.exchangeTokenAddress
                );
            } else {
                //cancel vote and stay on current treshold
            }
        } else {
            if (project.currentTreshold < project.nbOfTresholds - 1) {
                projects[id].currentTreshold++;
            } else {
                projects[id].active = false;
            }

            AddWithdrawalAmount(
                project.owner,
                currentTreshold.budget,
                project.exchangeTokenAddress
            );
        }
    }

    //add withdrawal amount amount of token exchangeTokenAddress to owner address
    function AddWithdrawalAmount(
        address owner,
        uint256 amount,
        address exchangeTokenAddress
    ) private {
        availableWithdrawals[owner][exchangeTokenAddress] += amount;
    }
}
