pragma solidity 0.4.24;

import "./Ownable.sol";
import "./EIP20Interface.sol";

contract TimeLock2 is Ownable{
    struct LockedAccount {
        uint256[9] claimableTokens;
        uint256 releaseState;
        uint256 totalLocked;
    }

    // 6 lock type: KYC1-2-3-4,OneYear,TwoYear
    // 9 time index: Prelaunch,1-2-3-4-5-6 months,1-2 years
    // IT'S DECLARED BACKWARD IN SOLIDITY BUT USE NORMALLY
    uint256[9][6] unlockRates;
    mapping(address=>LockedAccount) accounts;

    // time lock constraint calculated from crowdsale launch time
    uint256[9] stateTime;

    EIP20Interface token;

    // true: owner can add, everyone cant claim
    // false: owner cant add, everyone can claim
    bool stageFlag = true;

    event TokenClaimed(address beneficiary,uint256 amount);
    event TokenAdded(address beneficiary,uint256 lockType,uint256 amount);
    event StageSwitched();

    constructor(address tokenAddr, uint256 launchTime) public {
        token = EIP20Interface(tokenAddr);
        initStateTime(launchTime);
        initUnlockRates();
    }

    function initStateTime(uint256 launchTime) internal {
        stateTime[0] = 0;
        stateTime[1] = launchTime + 30 * 1 days;
    }

    function initUnlockRates() internal {
        // KYC 1
        unlockRates[0][0] = 333;
        unlockRates[0][3] = 333;
        unlockRates[0][6] = 334;
        // OneYear
        unlockRates[4][7] = 1000;
        // TwoYear
        unlockRates[5][8] = 1000;
    }

    // Consider making crowdsale contract create this contract and call this
    // or use time constraint instead
    // to avoid manually switching stage
    function stageSwitch() public
    onlyOwner
    returns(bool) {
        // this function can only be used once
        require(stageFlag == true);

        stageFlag = false;
        emit StageSwitched();
        return true;
    }

    function addLockedTokens (address beneficiary,uint256 lockType, uint256 amount) public 
    onlyOwner
    returns(bool){
        // perform checks 
        require(stageFlag == true);
        require(beneficiary != address(0));

        // bounds checking
        require(lockType < 6 && lockType >= 0);
        require(amount > 0);

        // perform calculations for claimable token per time index 
        // based on unlock rates according to lock type and time index

        // keep track of total for logging and eth conversion later
        accounts[beneficiary].totalLocked += amount;

        // increase claimble per index by amount*rate
        uint256 arrLength = accounts[beneficiary].claimableTokens.length;
        for (uint256 timeIndex = 0; timeIndex < arrLength; timeIndex++) {
            // need to apply SafeMath
            accounts[beneficiary].claimableTokens[timeIndex] += (amount * (unlockRates[lockType][timeIndex])/1000);
        }

        emit TokenAdded(beneficiary, lockType, amount);

        return true;
    }

    function claimToken() public returns (bool) {
        // perform checks
        require(stageFlag == false);

        
        uint256 arrLength = accounts[msg.sender].claimableTokens.length;

        // Sum all claimable token up till now
        // set them to 0 after doing sum
        // update releaseState: it means user is claiming all tokens 
        // from all state until now combined
        // do token transfer for sum to account 
        uint256 currentClaimableSum = 0;

        // releaseState will default to 0
        for (uint256 accState = accounts[msg.sender].releaseState;
            accState < arrLength && 
            block.timestamp > stateTime[accState];
            accState++) {
            currentClaimableSum += accounts[msg.sender].claimableTokens[accState];

            // might not need because accState starts from the next state
            // only here for security reasons
            accounts[msg.sender].claimableTokens[accState] = 0;
        }

        // update state and transfer all claimable
        accounts[msg.sender].releaseState = accState;
        token.transfer(msg.sender,currentClaimableSum);

        emit TokenClaimed(msg.sender,currentClaimableSum);
    }
}