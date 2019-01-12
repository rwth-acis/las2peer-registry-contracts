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

// account[1] for 'differ employ cook sport clinic wedding melody column pave stuff oak price'
const credentials = {
    account: '0x4d341f10a9bdd3ffb1a4e0c5ddea857c7f885a42',
    privateKey: '0x6129ae2b6bfbae676f66e624495812394ecb22b8e0c1475366f58c2a29ed8a81'
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
        userRegistry.nameIsValid('0x0').should.eventually.be.false
    )

    it('example name is valid', () =>
        userRegistry.nameIsValid(agent.name).should.eventually.be.true
    )

    it('example name is not taken', () =>
        userRegistry.nameIsTaken(agent.name).should.eventually.be.false
    )

    it('registration is possible, emits event, and makes name taken/unavailable', async () => {
        let registrationResult = await userRegistry.register(agent.name, agent.id, agent.publicKey)

        return Promise.all([
            registrationResult.should.nested.include({
                'logs[0].event': 'UserRegistered',
                'logs[0].args.name': '0x416c696365000000000000000000000000000000000000000000000000000000' // web3.fromAscii(agent.name, 64) // broken in web3 v0.2x.x
            }),
            userRegistry.nameIsTaken(agent.name).should.eventually.be.true,
            userRegistry.nameIsAvailable(agent.name).should.eventually.be.false,
            userRegistry.isOwner(accounts[0], agent.name).should.eventually.be.true,
            userRegistry.isOwner(accounts[1], agent.name).should.eventually.be.false
        ])
    })

    it('registration with duplicate name is not possible', async () => {
        await userRegistry.register(agent.name, agent.id, agent.publicKey)
        return userRegistry.register(agent.name, agent.id, agent.publicKey).should.be.rejected
    })

    it('delegated registration with signature of some other account correctly reflects ownership', async () => {
        let data = web3.eth.abi.encodeFunctionCall(userRegistry.abi[7], [agent.name, agent.id, agent.publicKey])
        let dataHash = web3.utils.soliditySha3(data)
        let signature = web3.eth.accounts.sign(dataHash, credentials.privateKey).signature
        await userRegistry.delegatedRegister(agent.name, agent.id, agent.publicKey, signature)

        let owner = (await userRegistry.users(agent.name)).owner // does this work? DEBUG

        // FIXME: okay, so the signature is apparently valid but does not belong to the account we expected:
        // it's 0xf5470A799D86E4D7e204aD8d16f52bb7d4d48aBb
        // expected 0x4d341f10a9bdd3ffb1a4e0c5ddea857c7f885a42
        // my first guess is that the private key format / encoding is wrong
        // but web3.eth.accounts.privateKeyToAccount(credentials.privateKey) yields expected

        return Promise.all([
            userRegistry.nameIsTaken(agent.name).should.eventually.be.true,
            userRegistry.isOwner(credentials.account, agent.name).should.eventually.be.true,
            userRegistry.isOwner(accounts[0], agent.name).should.eventually.be.false
        ])
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
