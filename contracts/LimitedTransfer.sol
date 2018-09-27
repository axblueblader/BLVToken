pragma solidity 0.4.24;

contract LimitedTransfer {
    bool disabledTransfer;

    event TransferDisabled(address _by);
    event TransferEnabled(address _by);

    constructor() public {
        disabledTransfer = false;
    }

    modifier canTransfer {
        require(disabledTransfer == false);
        _;
    }

    function enableTransfering() public {
        disabledTransfer = false;
        emit TransferEnabled(msg.sender);
    }

    function disableTransfering() public canTransfer {
        disabledTransfer = true;
        emit TransferDisabled(msg.sender);
    }
}