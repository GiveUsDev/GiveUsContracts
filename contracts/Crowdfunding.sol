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

    struct Donator {
        address donatorAddress;
        uint256 amountDonated;
    }

    struct Treshold {
        uint256 budget;
        VoteSession voteSession;
    }

    struct VoteSession {
        bool isVotingInSession;
        uint256 numberOfVotes;
        uint256 positiveVotes;
        uint256 negativeVotes;
    }

    //TODO support vote
    struct Project {
        address owner;
        address exchangeTokenAddress;
        string name;
        string assoName;
        string[] teamMembers;
        string description;
        uint256 requiredAmount;
        uint256 currentAmount;
        //
        Treshold[] tresholds; // each treshold has its own budget like [10,20,30] this means the total budget is 10+20+30 //can add alter a function to add new tresholds
        uint256 currentTreshold;
    }

    address[] public supportedTokens;
    mapping(uint256 => Project) public projects; //get project by id
    mapping(address => uint[]) public myProjects;
    mapping(uint256 => mapping(address => bool)) public donatorsPerProjects;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public tresholdVoteFromAddress;

    mapping(address => mapping(address => uint256)) public availableWithdrawals;

    Counters.Counter private idCounter;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
    }

    function CreateProject(Project calldata _project) public {
        require(
            IsTokenSupported(_project.exchangeTokenAddress),
            "Token not supported"
        );
        uint256 currentId = idCounter.current();
        projects[currentId] = _project;
        idCounter.increment();
    }

    function GoToNextTreshold(uint256 id) public {
        Project memory project = projects[id];
        require(msg.sender == project.owner, "You are not allowed");
        require(
            project.currentTreshold < project.tresholds.length + 1,
            "Project Funded"
        );

        if (
            project.currentAmount >=
            project.tresholds[project.currentTreshold].budget
        ) {
            UnlockNextTreshold(id);
        }
    }

    //TODO Possible DOS because of Array
    function IsDonator(address user, uint256 id) public view returns (bool) {
        Donator[] memory donators = projects[id].donators;

        for (uint256 i = 0; i < donators.length; i++) {
            if (donators[i].donatorAddress == user) {
                return true;
            }
        }

        return false;
    }

    function IsTokenSupported(address token) public view returns (bool) {
        address[] memory tempSupportedTokens = supportedTokens;

        for (uint256 i = 0; i < tempSupportedTokens.length; i++) {
            if (tempSupportedTokens[i] == token) {
                return true;
            }
        }

        return false;
    }

    function StartTresholdVoting(uint256 id) external {
        Project memory project = projects[id];
        require(msg.sender == project.owner, "You are not allowed");
        require(
            !project
                .tresholds[project.currentTreshold]
                .voteSession
                .isVotingInSession,
            "Already in Voting Session"
        );
        require(
            project.currentTreshold < project.tresholds.length + 1,
            "Project Funded"
        );
        require(
            project.currentAmount >=
                project.tresholds[project.currentTreshold].budget,
            "Treshold not reached yet"
        );

        projects[id]
            .tresholds[project.currentTreshold]
            .voteSession
            .isVotingInSession = true;
    }

    // we vote + or - for the current treshold
    function VoteForTreshold(uint256 id, bool vote) external {
        Project memory project = projects[id];
        require(IsDonator(msg.sender, id), "Only Donators can vote");

        VoteSession memory vs = project
            .tresholds[project.currentTreshold]
            .voteSession;
        vs.numberOfVotes++;
        vote ? vs.positiveVotes++ : vs.negativeVotes++;

        projects[id].tresholds[project.currentTreshold].voteSession = vs;
    }

    function WithdrawFunds(address exchangeTokenAddress) external {
        uint256 amountToWithdraw = availableWithdrawals[msg.sender][
            exchangeTokenAddress
        ];
        require(amountToWithdraw > 0, "No Funds to withdraw");
        IERC20(exchangeTokenAddress).transfer(msg.sender, amountToWithdraw);
    }

    function AddNewSupportedToken(address tokenAddress)
        external
        onlyRole(UPDATER_ROLE)
    {
        supportedTokens.push(tokenAddress);
    }

    function UnlockNextTreshold(uint256 id) private {
        Project memory project = projects[id];
        AddWithdrawalAmount(
            project.owner,
            project.tresholds[project.currentTreshold].budget,
            project.exchangeTokenAddress
        );

        projects[id].currentTreshold++;
    }

    function AddWithdrawalAmount(
        address owner,
        uint256 amount,
        address exchangeTokenAddress
    ) private {
        availableWithdrawals[owner][exchangeTokenAddress] += amount;
    }
}
