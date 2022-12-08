// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface Project {

    //TODO support vote
    struct Project{
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
        uint currentTreshold;
        Donator[] donators;
    }
}