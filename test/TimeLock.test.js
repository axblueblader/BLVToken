// web3 is a global variable, injected by Truffle.js
const BigNumber = web3.BigNumber

const TimeLockContract = artifacts.require('TimeLock')

const TokenContract = artifacts.require('StandardToken')

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
var should = require('chai').should()
var expect = require('chai').expect
var assert = require('chai').assert

// helper function to test exceptions
const expectThrow = require('./helper/throwhelper.js');



contract('TimeLockContract', function (walletAddresses) {
    let me = walletAddresses[0]
    let friend = walletAddresses[1]

    beforeEach(async function () {
        tokenContract = await TokenContract.new(100, 'Blu Token', 1, 'BLV')
        contract = await TimeLockContract.new(tokenContract.address,0);
    })

    // afterEach(async function () {
    //     await contract.selfDestruct({ from: me });
    // });

    it('should exist', async function () {
        contract.should.exist;
    })

    it('should add beneficiary account', async function() {
        await contract.addAccount(friend,0,100,{from: me});
        //let totalLocked = await contract.viewTotalLocked({from: friend});
        //totalLocked.should.be.bignumber.equal(new BigNumber(100));
    })

    it('should not let other add beneficiary account', async function() {
        let tx = contract.addAccount(friend,0,100,{from: friend});
        await expectThrow(tx);
    })

    it('should not let add account after disabled', async function() {
        await contract.disableAccountAddRemove();
        let tx = contract.addAccount(friend,0,100,{from: me});
        await expectThrow(tx);
    })
})