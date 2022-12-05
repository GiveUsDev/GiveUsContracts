// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Crowdfunding is AccessControl, Pausable{
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    struct Donator{
        address donatorAddress;
        uint amountDonated;
    }

    //TODO support vote
    struct Project{
        string name;
        string assoName;
        string[] teamMembers;
        string description;
        uint256 requiredAmount;
        uint256 currentAmount;
        uint256[] tresholds; // each treshold has its own budget like [10,20,30] this means the total budget is 10+20+30 
        uint currentTreshold;
        address owner;
        address exchangeTokenAddress;
        Donator[] donators;
        bool isVotingInSession;
    }

    address[] public supportedTokens;
    mapping (uint256 => Project) public projects;
    mapping (address => mapping (address => uint)) public availableWithdrawals;

    Counters.Counter private idCounter;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
    }

    function CreateProject(Project calldata _project) public {
        require(IsTokenSupported(_project.exchangeTokenAddress), "Token not supported");
        uint256 currentId = idCounter.current();
        projects[currentId] = _project;
        idCounter.increment();
    }

    function GoToNextTreshold(uint id) public {
        Project memory project = projects[id];
        require(msg.sender == project.owner, "You are not allowed");
        require(project.currentTreshold < project.tresholds.length +1, "Project Funded");

        if(project.currentAmount >= project.tresholds[project.currentTreshold]){
            UnlockNextTreshold(id);
        }
    }

    //TODO Possible DOS because of Array
    function IsDonator(address user, uint id) public view returns(bool){
        Donator[] memory donators = projects[id].donators;

        for(uint i = 0; i < donators.length; i++){
            if(donators[i].donatorAddress == user){
                return true;
            }
        }

        return false;
    }

    function IsTokenSupported(address token) public view returns(bool){
        address[] memory tempSupportedTokens = supportedTokens;

        for(uint i = 0; i < tempSupportedTokens.length; i++){
            if(tempSupportedTokens[i] == token){
                return true;
            }
        }

        return false;
    }

    function StartTresholdVoting(uint id) external {
        Project memory project = projects[id];
        require(msg.sender == project.owner, "You are not allowed");
        require(!project.isVotingInSession, "Already in Voting Session");
        require(project.currentTreshold < project.tresholds.length +1, "Project Funded");
        require(project.currentAmount >= project.tresholds[project.currentTreshold], "Treshold not reached yet");

        projects[id].isVotingInSession = true;
    }

    //TODO do vote
    function VoteForTreshold(uint id, bool vote) external {
        Project memory project = projects[id];
        require(IsDonator(msg.sender, id), "Only Donators can vote");
    }

    function WithdrawFunds(address exchangeTokenAddress) external {
        uint amountToWithdraw = availableWithdrawals[msg.sender][exchangeTokenAddress];
        require(amountToWithdraw>0, "No Funds to withdraw");
        IERC20(exchangeTokenAddress).transfer(msg.sender, amountToWithdraw);
    }

    function AddNewSupportedToken(address tokenAddress) external onlyRole(UPDATER_ROLE){
        supportedTokens.push(tokenAddress);
    }

    function UnlockNextTreshold(uint id) private {
        Project memory project = projects[id];
        AddWithdrawalAmount(project.owner, project.tresholds[project.currentTreshold], project.exchangeTokenAddress);

        projects[id].currentTreshold++;
    }

    function AddWithdrawalAmount(address owner, uint amount, address exchangeTokenAddress) private {
        availableWithdrawals[owner][exchangeTokenAddress] += amount;
    }
    
}