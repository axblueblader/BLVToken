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
expectThrow = async (promise) => {
  try {
    await promise;
  } catch (err) {
    return;
  }
  assert(false, 'Expected throw not received');
}


contract('TokenContract', function (walletAddresses) {
  let me = walletAddresses[0]
  let friend = walletAddresses[1]
  let contract

  beforeEach(async function () {
    contract = await TokenContract.new(100, 'Blu Token', 1, 'BLV')
  })

  it('should create contract', async function () {
    contract.should.exist
  })

  it('should not create contract with amount = 0', async function () {
    let wrongContract = TokenContract.new(0,'Zero',1,'ZRO');
    await expectThrow(wrongContract)
  })

  it('should initialize balance correctly', async function () {
    
    const myBalance = await contract.balanceOf(me)
    myBalance.should.be.bignumber.equal(new BigNumber(100))

    const friendBalance = await contract.balanceOf(friend, {from: friend})
    friendBalance.should.be.bignumber.equal(new BigNumber(0))
  })

  it('should transfer(friend,10) correctly from me', async function () {
    // initially i have 100 BLV
    let myBalance = await contract.balanceOf(me)
    myBalance.should.be.bignumber.equal(new BigNumber(100))

    // transfering 10 BLV to friend
    const amount = 10;
    await contract.transfer(friend, amount, { from: me })

    // now i should have 90 BLV	
    myBalance = await contract.balanceOf(me)
    myBalance.should.be.bignumber.equal(new BigNumber(100 - amount))

    // friend should have 10 BLV
    let friendBalance = await contract.balanceOf(friend, { from: friend })
    friendBalance.should.be.bignumber.equal(new BigNumber(amount))
  })

  it('should transfer to yourself correctly', async function () {
    let myBalance = await contract.balanceOf(me);
    myBalance.should.be.bignumber.equal(new BigNumber(100));

    await contract.transfer(me,100,{from: me});
    let myNewBalance = await contract.balanceOf(me);
    myNewBalance.should.be.bignumber.equal(new BigNumber(myBalance));
  })

  it('should not show me balance of my friend', async function () {
    let tx = contract.balanceOf(friend, { from: me });
    await expectThrow(tx);
  })

  it('should not transfer to address(0)', async function () {
    const tx = contract.transfer(0,10,{from: me});
    await  expectThrow(tx);
  })

  it('should not show allowance to other callers', async function () {
    const tx = contract.allowance(me,friend,{from: friend})
    await expectThrow(tx);
  })

  it('should change {allowed[me][friend]} correctly', async function () {
    const tx = await contract.approve(friend,20,{from: me});
    let allowance = await contract.allowance(me,friend,{from: me})

    allowance.should.be.bignumber.equal(new BigNumber(20));
  })

  it('should not allow more than owner balance', async function () {
    const tx = contract.allowance(friend,101,{from: me});
    await expectThrow(tx);
  })

  it('should allow delegate to transfer', async function () {
    await contract.approve(friend,20,{from: me});

    let friend2 = walletAddresses[2];
    await contract.transferFrom(me,friend2,10,{from: friend});

    let friend2Balance = await contract.balanceOf(friend2,{from: friend2});
    friend2Balance.should.be.bignumber.equal(new BigNumber(10));

    let friendBalance = await contract.balanceOf(friend,{from: friend});
    friendBalance.should.be.bignumber.equal(new BigNumber(0));

    let myBalance = await contract.balanceOf(me,{from: me});
    myBalance.should.be.bignumber.equal(new BigNumber(90));
  })

  it('should not allow delegate to transfer more than allowance',async function () {
    await contract.approve(friend,20,{from: me});

    let friend2 = walletAddresses[2];
    const tx = contract.transferFrom(me,friend2,21,{from: friend});

    await expectThrow(tx);
  })

  it('should not allow delegate to transfer more than owner balance', async function () {
    await contract.approve(friend,101,{from: me});

    let friend2 = walletAddresses[2];
    const tx = contract.transferFrom(me.friend2,101,{from: friend});

    await expectThrow(tx);
  })
})

