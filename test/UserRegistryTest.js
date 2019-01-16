require('./support/setup')

const UserRegistryContract = artifacts.require('UserRegistry')

// NOTE: *returning* the promise assertions is important
// at least I think that's what caused a bug that kept me busy for a while
// it works sometimes, other times it does not (yeah, great fun ...)
// see:
//     "either return or notify(done) must be used with promise assertions"
//     https://www.chaijs.com/plugins/chai-as-promised/

const agent = {
    name: web3.utils.utf8ToHex('Alice'),
    id: '0x1c4421af4d723edc834463c015a5b76ddce4cd679227e963c14941fcef2ee716bf8fbeabdce7a08ee2c261b16772b5bacbbca086746632b58d6658089c3fc480',
    publicKey: web3.utils.utf8ToHex('MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCqGKukO1De7zhZj6+H0qtjTkVxwTCpvKe4eCZ0FPqri0cb2JZfXJ/DgYSF6vUpwmJG8wVQZKjeGcjDOL5UlsuusFncCzWBQ7RKNUSesmQRMSGkVb1/3j+skZ6UtW+5u09lHNsj6tQ51s1SPrCBkedbNf0Tp0GbMJDyR4e9T04ZZwIDAQAB')
}

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
        (userRegistry.nameIsValid('0x0')).should.eventually.be.false
    )

    it('example name is valid', () =>
        (userRegistry.nameIsValid(agent.name)).should.eventually.be.true
    )

    it('example name is not taken', () =>
        (userRegistry.nameIsTaken(agent.name)).should.eventually.be.false
    )

    it('registration is possible, emits event, and makes name taken/unavailable', async () => {
        let registrationResult = await userRegistry.register(agent.name, agent.id, agent.publicKey)

        return Promise.all([
            registrationResult.should.nested.include({
                'logs[0].event': 'UserRegistered',
                'logs[0].args.name': '0x416c696365000000000000000000000000000000000000000000000000000000' // web3.fromAscii(agent.name, 64) // broken in web3 v0.2x.x
            }),
            (userRegistry.nameIsTaken(agent.name)).should.eventually.be.true,
            (userRegistry.nameIsAvailable(agent.name)).should.eventually.be.false
        ])
    })

    it('registration with duplicate name is not possible', async () => {
        await userRegistry.register(agent.name, agent.id, agent.publicKey)
        return (userRegistry.register(agent.name, agent.id, agent.publicKey)).should.be.rejected
    })

    it('name can be transferred', async function () {
        if (accounts.length < 2) {
            this.skip()
        }

        await userRegistry.register(agent.name, agent.id, agent.publicKey, { from: accounts[0] })
        let transferResult = await userRegistry.transfer(agent.name, accounts[1])
        return Promise.all([
            transferResult.should.nested.include({
                'logs[0].event': 'UserTransferred',
                'logs[0].args.name': '0x416c696365000000000000000000000000000000000000000000000000000000' // web3.fromAscii(agent.name, 64) // broken
            })
        ])
    })
})
