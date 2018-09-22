var HelloWorld = artifacts.require('HelloWorld')

// random caveats:
// - using chai expect partials (e.g., `then(expect(3).to.equal)`) mess up the test hooks somehow

// this contract function is provided by truffle, see their testing docs
contract('HelloWorld', accounts => {
    it('direct call of noop retuns tx which happens to use 21765 gas', () => {
        HelloWorld.deployed().then(i => i.noop(3)).then(r => expect(r.receipt.gasUsed).to.equal(21765))
    })

    it('noop function returns nothing', () => {
        HelloWorld.deployed().then(i => i.noop.call(3)).then(r => expect(r).to.deep.equal([]))
    })

    it('executing pure function directly returns value', () => {
        HelloWorld.deployed().then(i => i.pureF(3)).then(r => expect(3).to.equal(r))
    })

    it('calling pure function via call returns value', () => {
        HelloWorld.deployed().then(i => i.pureF.call(3)).then(r => expect(3).to.equal(r))
    })

    it('setting and getting seems consistent', () => {
        HelloWorld.deployed().then(i => {
            const testVal = 23
            i.setterF(testVal)
            i.viewF(1 /* ignored anyway */).then(r => expect(testVal).to.equal(r))
        })
    })
})
