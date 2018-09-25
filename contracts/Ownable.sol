pragma solidity 0.4.24;

contract Ownable {
    address public owner;

    event OwnershipChanged(address _from,address _to);
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function viewOwner() public view returns(address) {
        return owner;
    }

    function trasnferOwnership(address _to) public onlyOwner {
        owner = _to;
        emit OwnershipChanged(msg.sender,_to);
    }
}