const BigNumber = web3.BigNumber
require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .should()

const HelloWorldContract = artifacts.require('HelloWorld')

// TODO: possibly use chai-as-promised to simplify tests:
//       https://github.com/domenic/chai-as-promised

const v = 23 // some test value

// this contract function is provided by truffle, see their testing docs
contract('HelloWorld', accounts => {
    beforeEach(async () => {
        let instance = await HelloWorldContract.deployed()
        this.i = instance
    })

    it('direct call of noop retuns tx which happens to use 21765 gas', async () => {
        (await this.i.noop(v)).receipt.gasUsed.should.equal(21765)
    })

    it('noop function returns nothing', async () => {
        (await this.i.noop.call(v)).should.deep.equal([])
    })

    it('executing pure function directly returns value', async () => {
        (await this.i.pureF(v)).should.be.bignumber.equal(v)
    })

    it('calling pure function via call returns value', async () => {
        (await this.i.pureF.call(v)).should.be.bignumber.equal(v)
    })

    it('setting and getting seems consistent', async () => {
        await this.i.setterF(v);
        (await this.i.viewF(1 /* dummy arg */)).should.be.bignumber.equal(v)
    })
})
