pragma solidity 0.4.24;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./EIP20Interface.sol";

contract TimeLock is Ownable{
    using SafeMath for uint256;

    struct Beneficiary {
        address wallet;
        uint256 accType;
        uint256 claimable;
        uint256 totalLocked;
    }

    EIP20Interface public token;
    mapping(address=>uint256) addressIndices;
    Beneficiary[] public accounts;
    uint256 public releaseState;

    // define a table for Rates[accType][releaseState] = rate
    mapping(uint256 => mapping(uint256 => uint256)) Rates;

    event AccountAdded(address _to,uint256 _accType, uint256 _totalLocked);
    event AddAccountDisabled();
    event RemoveAccountDisabled();
    event StateChangedTo(uint256 to);

    constructor(address tokenAddress) public {
        token = EIP20Interface(tokenAddress);
        releaseState = 0;
        owner = msg.sender;
    }

    function nextState() internal {
        releaseState = releaseState.add(1);
    }

    function addAccount(address _to,uint256 _accType, uint256 _totalLocked) public onlyOwner {
        require(_to != address(0));
        require(_accType < 5);
        require(_totalLocked > 0);
        accounts.push(Beneficiary(
            _to,
            _accType,
            _totalLocked,
            0
        ));
        addressIndices[_to] = accounts.length;
        emit AccountAdded(_to,_accType,_totalLocked);
    }

    function removeAccount(address _addr) public onlyOwner {
        require(_addr != address(0));
        require( addressIndices[_addr] >= 0 && addressIndices[_addr] < accounts.length);

        uint256 accIndex = addressIndices[_addr];
        accounts[accIndex].totalLocked = 0;
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
        // releaseForType1()
        // releaseForType2()
        // ...
        // each releaseForType checks conditions then loop through
        // all accounts of that type to perform 
        
        // TODO: CHECK TIME CONDITION ALONG WITH STATE
        for (uint256 index = 0; index < accounts.length; index++) {
            uint256 rate = Rates[accounts[index].accType][releaseState];
            accounts[index].claimable = accounts[index].claimable.add(accounts[index].totalLocked.div(rate));
        }
        // claimable = claimable.add(totalLocked.div(rate));
        // then fire events
        nextState();
        emit StateChangedTo(releaseState);
        return true;
    }
}