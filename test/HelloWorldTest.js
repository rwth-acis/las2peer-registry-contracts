require('./support/setup.js')

const HelloWorldContract = artifacts.require('HelloWorld')

const v = 23 // some test value

// this contract function is provided by truffle, see their testing docs
contract('HelloWorld', accounts => {
    beforeEach(async () => {
        let instance = await HelloWorldContract.deployed()
        this.i = instance
    })

    it('direct call of noop retuns tx which happens to use 21765 gas', async () => {
        (this.i.noop(v)).should.eventually.nested.include({ 'receipt.gasUsed': 21765 })
    })

    it('noop function returns nothing', async () => {
        (this.i.noop.call(v)).should.eventually.deep.equal([])
    })

    it('executing pure function directly returns value', async () => {
        (this.i.pureF(v)).should.eventually.be.bignumber.equal(v)
    })

    it('calling pure function via call returns value', async () => {
        (this.i.pureF.call(v)).should.eventually.be.bignumber.equal(v)
    })

    it('setting and getting seems consistent', async () => {
        await this.i.setterF(v);
        (this.i.viewF(1 /* dummy arg */)).should.eventually.be.bignumber.equal(v)
    })
})
