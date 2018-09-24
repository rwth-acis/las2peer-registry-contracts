const HelloWorldContract = artifacts.require('HelloWorld')

// random caveats:
// - using chai expect(..).to.equal(..) does not work for BigNumbers
// - using chai expect(..).to.equal as partial also seems to sometimes fail mysteriously
//
// .. so let's just avoid using chai BDD style asserts for now
//
// TODO: possibly get around the BigNumber issue as described here:
//       https://medium.com/@gus_tavo_guim/beautifying-your-smart-contract-tests-with-javascript-4d284efcb2e8
//
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
        expect((await this.i.noop(v)).receipt.gasUsed).to.equal(21765)
    })

    it('noop function returns nothing', async () => {
        expect(await this.i.noop.call(v)).to.deep.equal([])
    })

    it('executing pure function directly returns value', async () => {
        expect((await this.i.pureF(v)).toNumber()).to.equal(v)
    })

    it('calling pure function via call returns value', async () => {
        expect((await this.i.pureF.call(v)).toNumber()).to.equal(v)
    })

    it('setting and getting seems consistent', async () => {
        await this.i.setterF(v)
        expect((await this.i.viewF(1 /* dummy arg */)).toNumber()).to.equal(v)
    })
})
