pragma solidity 0.4.24;

import "./Ownable.sol";
import "./ERC20.sol";
import "./LimitedTransfer.sol";

contract StandardToken is ERC20, Ownable, LimitedTransfer {
    constructor (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        require(_initialAmount > 0);
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        owner = msg.sender;
    }

    function selfDestruct() public onlyOwner {
        selfdestruct(msg.sender);
    }

    function transfer(address _to, uint256 _value) public canTransfer returns (bool success) {
        super.transfer(_to,_value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfer  returns (bool success) {
        super.transferFrom(_from,_to,_value);
        return true;
    }

    function enableTransfering() public onlyOwner {
        super.enableTransfering();
    }

    function disableTransfering() public onlyOwner {
        super.disableTransfering();
    }

    
}
