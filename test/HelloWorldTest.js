require('./support/setup.js')

const HelloWorldContract = artifacts.require('HelloWorld')

const v = 23 // some test value

// this contract function is provided by truffle, see their testing docs
contract('HelloWorld', accounts => {
    let helloWorld

    beforeEach(async () => {
        helloWorld = await HelloWorldContract.new()
    })

    it('direct call of noop retuns tx which happens to use 21765 gas', () =>
        (helloWorld.noop(v)).should.eventually.nested.include({ 'receipt.gasUsed': 21765 })
    )

    it('noop function returns nothing', () =>
        (helloWorld.noop.call(v)).should.eventually.be.an('array').that.is.empty
    )

    it('executing pure function directly returns value', () =>
        (helloWorld.pureF(v)).should.eventually.bignumber.equal(v)
    )

    it('calling pure function via call returns value', () =>
        (helloWorld.pureF.call(v)).should.eventually.bignumber.equal(v)
    )

    it('setting and getting seems consistent', async () => {
        await helloWorld.setterF(v)
        return (helloWorld.viewF(1 /* dummy arg */)).should.eventually.bignumber.equal(v)
    })

    it('emitted event is visible in response log', () =>
        (helloWorld.emitEvent(v)).should.eventually.nested.include({ 'logs[0].event': 'SimpleEvent' })
    )
})
