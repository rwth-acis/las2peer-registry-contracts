var HelloWorld = artifacts.require('HelloWorld')

// random caveats:
// - using chai expect(..).to.equal(..) only works, uh, sometimes

const v = 23 // some test value

// this contract function is provided by truffle, see their testing docs
contract('HelloWorld', accounts => {
    it('direct call of noop retuns tx which happens to use 21765 gas', () => {
        HelloWorld.deployed().then(i => i.noop(v)).then(r => assert.equal(r.receipt.gasUsed, 21765))
        HelloWorld.deployed().then(i => i.noop(v)).then(r => expect(21765).to.equal(r.receipt.gasUsed))
    })

    it('noop function returns nothing', () => {
        HelloWorld.deployed().then(i => i.noop.call(v)).then(r => assert.deepEqual(r, []))
        HelloWorld.deployed().then(i => i.noop.call(v)).then(r => expect(r).to.deep.equal([]))
    })

    it('executing pure function directly returns value', () => {
        HelloWorld.deployed().then(i => i.pureF(v)).then(r => assert.equal(r, v))
        HelloWorld.deployed().then(i => i.pureF(v)).then(r => expect(23 == r).to.be.true)
    })

    it('calling pure function via call returns value', () => {
        HelloWorld.deployed().then(i => i.pureF.call(v)).then(r => assert.equal(r, v))
    })

    it('setting and getting seems consistent', () => {
        HelloWorld.deployed().then(i => {
            i.setterF(v)
            i.viewF(1 /* ignored anyway */).then(r => assert.equal(r, v))
            i.viewF(1 /* ignored anyway */).then(expect(v).to.equal)
        })
    })
})
