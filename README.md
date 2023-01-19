# Crowdfunding contract

Tests almost done. Analysed with slither.


Test Coverage :
 
  Crowdfunding Contract
  
    Deployment
    
      USDC mint(uint amount)
        ✔ Should mint amount (200ms)
      Constructor()
        ✔ Should grant role DEFAULT_ADMIN_ROLE
        ✔ Should grant role PAUSER_ROLE
        ✔ Should grant role PAUSER_ROLE
      pause()
        ✔ should not pause, revert : Access Control (89ms)
        ✔ should not pause twice, revert : Pausable: paused
        ✔ should pause
      unpause()
        ✔ should not unpause, revert : Access Control (46ms)
        ✔ should not unpause not paused, revert : Pausable: not paused
        ✔ should unpause
      createProject(Project calldata _project)
        ✔ Should not create project, revert : Missing Role (39ms)
        ✔ Should not create project, revert : Paused
        ✔ Should not create project, revert : Token not supported
        ✔ Should not create project, revert : Need at least one Treshold
        ✔ Should create project (43ms)
      addNewSupportedToken(address tokenAddress)
        ✔ Should not add token, revert : AccessControl is missing role
        ✔ Should add token
      donateToProject(uint id, uint amount)
        ✔ Shouldnt donate, revert : Min amount is 1 (52ms)
        ✔ Shouldnt donate, revert : Project not Active
        ✔ Shouldnt donate, revert : Need to approve allowance first (49ms)
        ✔ Shouldnt donate, revert : Amount too small
        ✔ Should donate and not put voteInSession (60ms)
        ✔ Should donate put voteInSession (46ms)
        ✔ Should donate and emit Event
      isDonator(address user, uint256 id)
        ✔ Should Return true
      isTokenSupported(address token)
        ✔ Should Return true
        ✔ Should Return true
      voteForTreshold(uint256 id, bool vote)
        ✔ Shouldnt vote, revert : Only Donators can vote (54ms)
        ✔ Shouldnt vote, revert : Not in Voting Session
        ✔ Shouldnt vote, revert : Can Only Vote Once (55ms)
        ✔ Should vote positive
        ✔ Should vote negative
      endTresholdVoting(uint256 id)
        ✔ Shouldnt end voting, revert : You are not allowed
        ✔ Shouldnt end voting, revert : Not in Voting Session
        ✔ Should end voting, & set voting session false (77ms)
      DeliberateVote(uint256 id)
        ✔ Shouldnt deliberate, revert : Cant deliberate without votes
        ✔ Should deliberate positive 1-0 (46ms)
        ✔ Should deliberate negative whith 0-1 (45ms)
        ✔ Should deliberate equal whith 1-1 with 50% (132ms)
      withdrawFunds(address exchangeTokenAddress)
        ✔ Shouldnt withdrawFunds, revert : No Funds to withdraw
        ✔ Shouldnt withdrawFunds, revert : Token not supported
        ✔ Should withdrawFunds (101ms)
        ✔ Should withdrawFunds & emit event
      setDonationFee(uint projectId, uint16 newFee)
        ✔ Shouldnt change DonationFee, revert : Cant go above 10000 (90ms)
        ✔ Shouldnt change DonationFee, revert : Access Control
        ✔ Shouldnt change DonationFee & emit event
        ✔ Should change DonationFee (102ms)
        
    47 passing (2s)


File               |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
-------------------|----------|----------|----------|----------|----------------|
 contracts/        |      100 |    84.21 |      100 |      100 |                |
  Crowdfunding.sol |      100 |    84.21 |      100 |      100 |                |
  USDC.sol         |      100 |      100 |      100 |      100 |                |
All files          |      100 |    84.21 |      100 |      100 |                |
