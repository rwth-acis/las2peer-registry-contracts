require('./support/setup.js')

const HelloWorldContract = artifacts.require('HelloWorld')

const v = 23 // some test value

// this contract function is provided by truffle, see their testing docs
contract('HelloWorld', accounts => {
    let helloWorld

    beforeEach(async () => {
        helloWorld = await HelloWorldContract.deployed()
    })

    it('direct call of noop retuns tx which happens to use 21765 gas', async () => {
        (helloWorld.noop(v)).should.eventually.nested.include({ 'receipt.gasUsed': 21765 })
    })

    it('noop function returns nothing', async () => {
        (helloWorld.noop.call(v)).should.eventually.deep.equal([])
    })

    it('executing pure function directly returns value', async () => {
        (helloWorld.pureF(v)).should.eventually.be.bignumber.equal(v)
    })

    it('calling pure function via call returns value', async () => {
        (helloWorld.pureF.call(v)).should.eventually.be.bignumber.equal(v)
    })

    it('setting and getting seems consistent', async () => {
        await helloWorld.setterF(v);
        (helloWorld.viewF(1 /* dummy arg */)).should.eventually.be.bignumber.equal(v)
    })
})
