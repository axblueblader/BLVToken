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
})