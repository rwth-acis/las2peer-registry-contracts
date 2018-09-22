var HelloWorld = artifacts.require('HelloWorld')

// random caveats:
// - using chai expect(..).to.equal(..) does not work for BigNumbers

const v = 23 // some test value

// this contract function is provided by truffle, see their testing docs
contract('HelloWorld', accounts => {
    it('direct call of noop retuns tx which happens to use 21765 gas', () => {
        HelloWorld.deployed().then(i => i.noop(v)).then(r => assert.equal(r.receipt.gasUsed, 21765))
    })

    it('noop function returns nothing', () => {
        HelloWorld.deployed().then(i => i.noop.call(v)).then(expect([]).to.deep.equal)
    })

    it('executing pure function directly returns value', () => {
        HelloWorld.deployed().then(i => i.pureF(v)).then(r => assert.equal(r, v))
    })

    it('calling pure function via call returns value', () => {
        HelloWorld.deployed().then(i => i.pureF.call(v)).then(r => assert.equal(r, v))
    })

    it('setting and getting seems consistent', () => {
        HelloWorld.deployed().then(i => {
            i.setterF(v)
            i.viewF(1 /* ignored anyway */).then(expect(v).to.equal)
        })
    })
})
