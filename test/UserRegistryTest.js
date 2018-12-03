require('./support/setup.js')

const UserRegistryContract = artifacts.require('UserRegistry')

// NOTE: *returning* the promise assertions is important
// at least I think that's what caused a bug that kept me busy for a while
// it works sometimes, other times it does not (yeah, great fun ...)
// see:
//     "either return or notify(done) must be used with promise assertions"
//     https://www.chaijs.com/plugins/chai-as-promised/

const name = 'Alice'
const agentId = 'an-agent-id'
const text = 'lorem ipsum dolor sit amet'

contract('UserRegistryContract', accounts => {
    let userRegistry

    beforeEach(async () => {
        // using new to reset state, see
        // https://github.com/trufflesuite/truffle/issues/727
        // and in general
        // https://stackoverflow.com/questions/29508444/why-should-mocha-test-cases-be-stateless
        userRegistry = await UserRegistryContract.new()
    })

    it('empty (byte NULL) name is invalid', () =>
        (userRegistry.nameIsValid('')).should.eventually.be.false
    )

    it('example name is valid', () =>
        (userRegistry.nameIsValid(name)).should.eventually.be.true
    )

    it('example name is not taken', () =>
        (userRegistry.nameIsTaken(name)).should.eventually.be.false
    )

    it('registration is possible, emits event, and makes name taken/unavailable', async () => {
        let registrationResult = await userRegistry.register(name, agentId)

        return Promise.all([
            registrationResult.should.nested.include({
                'logs[0].event': 'UserRegistered',
                'logs[0].args.name': '0x416c696365000000000000000000000000000000000000000000000000000000' // web3.fromAscii(name, 64) // broken in web3 v0.2x.x
            }),
            (userRegistry.nameIsTaken(name)).should.eventually.be.true,
            (userRegistry.nameIsAvailable(name)).should.eventually.be.false
        ])
    })

    it('registration with duplicate name is not possible', async () => {
        await userRegistry.register(name, agentId)
        return (userRegistry.register(name, agentId)).should.be.rejected
    })

    it('setting a supplement and reading it from public var works', async () => {
        await userRegistry.register(name, agentId)
        await userRegistry.setSupplement(name, text)

        let registryEntry = await userRegistry.users(name)
        const supplementIndex = 3
        return (web3.toAscii(registryEntry[supplementIndex])).should.equal(text)
    })

    it('username access restriction works (for setting supplement)', async function () {
        if (accounts.length < 2 || accounts[0] === accounts[1]) {
            // this test requires two different accounts
            // some test setups may not provide that
            this.skip()
        }

        await userRegistry.register(name, agentId, { from: accounts[1] })

        // https://github.com/domenic/chai-as-promised#multiple-promise-assertions
        return Promise.all([
            (userRegistry.setSupplement(name, text, { from: accounts[0] })).should.be.rejected,
            (userRegistry.setSupplement(name, text, { from: accounts[1] })).should.be.fulfilled
        ])
    })

    it('name can be transferred', async function () {
        if (accounts.length < 2) {
            this.skip()
        }

        await userRegistry.register(name, agentId, { from: accounts[0] })
        let transferResult = await userRegistry.transfer(name, accounts[1])
        return Promise.all([
            (userRegistry.setSupplement(name, text, { from: accounts[1] })).should.be.fulfilled,
            transferResult.should.nested.include({
                'logs[0].event': 'UserTransferred',
                'logs[0].args.name': '0x416c696365000000000000000000000000000000000000000000000000000000' // web3.fromAscii(name, 64) // broken
            })
        ])
    })
})
