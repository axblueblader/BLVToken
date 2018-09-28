const OwnableContract = artifacts.require('Ownable')

require('chai')
    .use(require('chai-as-promised'))
var should = require('chai').should()
var expect = require('chai').expect
var assert = require('chai').assert

// helper function to test exceptions
const expectThrow = require('./helper/throwhelper.js');

contract('OwnableContract', function (walletAddresses) {
    let me = walletAddresses[0]
    let friend = walletAddresses[1]
    let contract
    beforeEach(async function () {
        contract = await OwnableContract.new();
    })

    // afterEach(async function () {
    //     await contract.selfDestruct({ from: me });
    // });

    it('should exist', async function () {
        contract.should.exist;
    })

    it('should have owner = msg.sender', async function () {
        let owner = await contract.viewOwner();
        owner.should.equal(me);
    })

    it('should transfer ownership to friend when called by me(owner)', async function () {
        await contract.trasnferOwnership(friend, { from: me });
        let owner = await contract.owner();
        owner.should.equal(friend);  
    })

    it('should fire OwnershipChanged event', async function () {
        let tx = await contract.trasnferOwnership(friend,{from: me});
        assert(tx.logs.length >0 && tx.logs[0].event == 'OwnershipChanged');
    })

    it('should not transfer ownership to friend when called by friend', async function () {
        const tx = contract.trasnferOwnership(friend, { from: friend });
        await expectThrow(tx);
    })


})