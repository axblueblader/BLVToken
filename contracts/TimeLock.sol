pragma solidity 0.4.24;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./EIP20Interface.sol";

contract TimeLock is Ownable{
    using SafeMath for uint256;

    struct Beneficiary {
        address wallet;
        
        // KYC1-2-3-4, one year, two year
        uint256 accType;

        // Token that has been unlocked
        uint256 claimable;

        // Amount of locked token that was bought/owned
        uint256 totalLocked;
    }

    EIP20Interface public token;
    mapping(address=>uint256) public addressIndices;
    
    // array store accounts of beneficiary with locked tokens
    Beneficiary[] public accounts;
    
    // keep track which state the timelock is at
    uint256 public releaseState;

    // keep track end time for each state
    uint256[] private stateTime;

    // crowdsale start time
    uint256 private launchTime;

    // define a table for unlockRates[accType][releaseState] = rate
    mapping(uint256 => mapping(uint256 => uint256)) public unlockRates;

    bool public accountChangesDisabled;

    event AccountAdded(address _to,uint256 _accType, uint256 _totalLocked);
    event AccountChangesDisabled();
    event StateChangedTo(uint256 to);

    constructor(address tokenAddress, uint256 crowdsaleLaunchTime) public {
        token = EIP20Interface(tokenAddress);
        releaseState = 0;
        owner = msg.sender;
        launchTime = crowdsaleLaunchTime;
        accountChangesDisabled = false;
        initStateTime();
    }

    function initStateTime() internal {
        stateTime.push(0);
        // 1 month after crowdsale launch
        stateTime.push(launchTime + 30 * 1 days);

        // 2 months after crowdsale launch
        stateTime.push(launchTime + 2 * 30 * 1 days);

        // 3 months after crowdsale launch
        stateTime.push(launchTime + 3 * 30 * 1 days);

        // 4 months after crowdsale launch
        stateTime.push(launchTime + 4 * 30 * 1 days);

        // 5 months after crowdsale launch
        stateTime.push(launchTime + 5 * 30 * 1 days);

        // 6 months after crowdsale launch
        stateTime.push(launchTime + 6 * 30 * 1 days);

        // 1 year after crowdsale launch
        stateTime.push(launchTime + 12 * 30 * 1 days);

        // 2 years after crowdsale launch
        stateTime.push(launchTime + 24 * 30 * 1 days);
    }
    // default of mapping already set to 0
    function initRates() internal {
        // KYC 1
        unlockRates[0][0] = 333;
        unlockRates[0][3] = 333;
        unlockRates[0][6] = 334;
        // OneYear
        unlockRates[4][7] = 1000;
        // TwoYear
        unlockRates[5][8] = 1000;
    }

    function nextState() internal {
        releaseState = releaseState.add(1);
    }

    function addAccount(address _to,uint256 _accType, uint256 _totalLocked) public onlyOwner {
        require(_to != address(0));
        require(_accType < 6 && _accType >= 0);
        require(_totalLocked > 0);
        require(accountChangesDisabled == false);
        accounts.push(Beneficiary(
            _to,
            _accType,
            0,
            _totalLocked
        ));
        addressIndices[_to] = accounts.length-1;
        emit AccountAdded(_to,_accType,_totalLocked);
    }

    function removeAccount(address _addr) public onlyOwner {
        require(_addr != address(0));   
        require( addressIndices[_addr] >= 0 && addressIndices[_addr] < accounts.length);
        require(accountChangesDisabled == false);

        uint256 accIndex = addressIndices[_addr];
        accounts[accIndex].totalLocked = 0;
    }

    function disableAccountAddRemove() public onlyOwner {
        accountChangesDisabled = true;
        emit AccountChangesDisabled();
    }

    function claimToken() public returns (bool){
        uint256 accIndex = addressIndices[msg.sender];
        // perform checks
        require (accIndex >= 0 && accIndex < accounts.length);
        require (accounts[accIndex].totalLocked != 0);
        
        if (accounts[accIndex].claimable >= 0 ){
            accounts[accIndex].claimable = 0;
            token.transfer(accounts[accIndex].wallet,accounts[accIndex].claimable);
        }
        else {
            return false;
        }
        return true;
    }

    function releaseToken() public onlyOwner returns (bool) {

        require(block.timestamp > stateTime[releaseState]);

        for (uint256 index = 0; index < accounts.length; index++) {
            uint256 rate = unlockRates[accounts[index].accType][releaseState];
            accounts[index].claimable = accounts[index].claimable.add((accounts[index].totalLocked.mul(rate)).div(1000));
        }
        
        nextState();
        emit StateChangedTo(releaseState);
        return true;
    }

    function viewAccInfo() public view returns(address,uint256,uint256,uint256) {
        uint256 accIndex = addressIndices[msg.sender];
        return (
            accounts[accIndex].wallet,
            accounts[accIndex].accType,
            accounts[accIndex].claimable,
            accounts[accIndex].totalLocked
        );
    }

    function getTotalLockedKYC() public returns (uint256){
        uint256 sum = 0;
        for (uint256 index = 0; index < accounts.length; index++) {
            if (accounts[index].accType < 4) {
                sum = sum.add(accounts[index].totalLocked);
            }
        }
        return sum;
    }

    function getTotalLockedDistribution() public returns (uint256) {
        uint256 sum = 0;
        for (uint256 index = 0; index < accounts.length; index++) {
            if (accounts[index].accType >= 4) {
                sum = sum.add(accounts[index].totalLocked);
            }
        }
        return sum;
    }

}