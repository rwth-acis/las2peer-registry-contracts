const HelloWorldContract = artifacts.require('HelloWorld')

// random caveats:
// - using chai expect(..).to.equal(..) does not work for BigNumbers
// - using chai expect(..).to.equal as partial also seems to sometimes fail mysteriously
// .. so let's just avoid using chai BDD style asserts for now

const v = 23 // some test value

// this contract function is provided by truffle, see their testing docs
contract('HelloWorld', accounts => {
    beforeEach(async () => {
        let instance = await HelloWorldContract.deployed()
        this.i = instance
    })

    it('direct call of noop retuns tx which happens to use 21765 gas', async () => {
        assert.equal((await this.i.noop(v)).receipt.gasUsed, 21765)
    })

    it('noop function returns nothing', async () => {
        assert.deepEqual(await this.i.noop.call(v), [])
    })

    it('executing pure function directly returns value', async () => {
        assert.equal(await this.i.pureF(v), v)
    })

    it('calling pure function via call returns value', async () => {
        assert.equal(await this.i.pureF.call(v), v)
    })

    it('setting and getting seems consistent', async () => {
        await this.i.setterF(v)
        expect(await this.i.viewF(1 /* dummy arg */), v)
    })
})
