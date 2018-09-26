// web3 is a global variable, injected by Truffle.js
const BigNumber = web3.BigNumber

// artifacts is a global variable, injected by Truffle.js
const TokenContract = artifacts.require('BLVToken')

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
var should = require('chai').should()
var expect = require('chai').expect
var assert = require('chai').assert

// helper function to test exceptions
const expectThrow = require('./helper/throwhelper.js');


contract('TokenContract - test en/dis-abling transfering', function (walletAddresses) {
    let me = walletAddresses[0]
    let friend = walletAddresses[1]
    let contract

    beforeEach(async function () {
        contract = await TokenContract.new(100, 'Blu Token', 1, 'BLV')
    })

    afterEach(async function () {
        await contract.selfDestruct({ from: me });
    })

    it('should have owner = me', async function() {
        let owner = await contract.owner();
        owner.should.equal(me);
    })

    it('should not let me transfer after disabling', async function() {
        await contract.disableTransfering();
        const tx = contract.transfer(friend,10);
        await expectThrow(tx);
    })

    it('should fire TransferDisabled event', async function() {
        let tx = await contract.disableTransfering();
        assert(tx.logs.length > 0 && tx.logs[0].event == 'TransferDisabled');
    })

    it('should fire TransferEnabled event', async function() {
        let tx = await contract.enableTransfering();
        assert(tx.logs.length > 0 && tx.logs[0].event == 'TransferEnabled');
    })

    it('should let me transfer again after enabling', async function() {
        await contract.disableTransfering();
        const tx = contract.transfer(friend,10);
        await expectThrow(tx);
        await contract.enableTransfering();
        await contract.transfer(friend,10);
        let friendBalance = await contract.balanceOf(friend,{from: friend});
        friendBalance.should.be.bignumber.equal(new BigNumber(10));
    })

    it('should not let friend change transfer settings',async function() {
        const tx = contract.disableTransfering({from: friend});
        await expectThrow(tx);
        const tx2 = contract.enableTransfering({from: friend});
        await expectThrow(tx2);
    })
})