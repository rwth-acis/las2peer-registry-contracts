var HelloWorldC = artifacts.require('HelloWorld')

// random caveats:
// - using chai expect(..).to.equal(..) does not work for BigNumbers
// - using chai expect(..).to.equal as partial also seems to sometimes fail mysteriously
// .. so let's just avoid using chai BDD style asserts for now

const v = 23 // some test value

function testFunction (action, assertion) {
    HelloWorldC.deployed().then(action.call).then(assertion.call)
}

// this contract function is provided by truffle, see their testing docs
contract('HelloWorldC', accounts => {
    it('direct call of noop retuns tx which happens to use 21765 gas', () => {
        testFunction(() => this.noop(v), () => assert.equal(this.receipt.gasUsed, 21765))
    })

    it('noop function returns nothing', () => {
        testFunction(() => this.noop.call(v), () => assert.deepEqual(this, []))
    })

    it('executing pure function directly returns value', () => {
        testFunction(() => this.pureF(v), () => assert.equal(this, v))
    })

    it('calling pure function via call returns value', () => {
        testFunction(() => this.pureF.call(v), () => assert.equal(this, v))
    })

    it('setting and getting seems consistent', () => {
        testFunction(() => {
            this.setterF(v)
            this.viewF(1 /* ignored anyway */)
        }, () => expect(this).to.equal(v))
    })
})
