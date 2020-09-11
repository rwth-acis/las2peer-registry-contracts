require('web3')

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

const service = {
    attrName: web3.utils.utf8ToHex('did/svc/LearningLayers'),
    value: web3.utils.utf8ToHex('https://api.learning-layers.eu/o/oauth2/'),
    validity: web3.utils.numberToHex(1000 * 365 * 86400) // a long time
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
                'logs[0].args.name': web3.utils.padRight(agent.name, 64)
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
                'logs[0].args.name': web3.utils.padRight(agent.name, 64)
            })
        ])
    })

    // DID
    it('sets attribute', async () => {
        await userRegistry.register(agent.name, agent.id, agent.publicKey)
        const setAttrResult = await userRegistry.setAttribute(agent.name, service.attrName, service.value, service.validity)

        return Promise.all([
            setAttrResult.should.nested.include({
                'logs[0].event': 'DIDAttributeChanged',
                'logs[0].args.userName': web3.utils.padRight(agent.name, 64),
                'logs[0].args.attrName': web3.utils.padRight(service.attrName, 64),
                'logs[0].args.value': web3.utils.padRight(service.value, 64)
            }),
            parseInt(setAttrResult.logs[0].args.validTo).should.be.at.most(Date.now() + 1000 * 365 * 86400)
        ])
    })

    it('sets previousChange correctly when setting an attribute', async () => {
        await userRegistry.register(agent.name, agent.id, agent.publicKey)
        const setAttrResult1 = await userRegistry.setAttribute(agent.name, service.attrName, service.value, service.validity)
        const setAttrResult2 = await userRegistry.setAttribute(agent.name, service.attrName, service.value, service.validity)

        return Promise.all([
            setAttrResult2.logs[0].args.previousChange.should.be.bignumber.equal(web3.utils.toBN(setAttrResult1.receipt.blockNumber))
        ])
    })

    it('revokes attribute', async () => {
        await userRegistry.register(agent.name, agent.id, agent.publicKey)
        await userRegistry.setAttribute(agent.name, service.attrName, service.value, service.validity)
        const revokeAttrResult = await userRegistry.revokeAttribute(agent.name, service.attrName)

        return Promise.all([
            revokeAttrResult.should.nested.include({
                'logs[0].event': 'DIDAttributeChanged',
                'logs[0].args.userName': web3.utils.padRight(agent.name, 64),
                'logs[0].args.attrName': web3.utils.padRight(service.attrName, 64)
            }),
            revokeAttrResult.logs[0].args.validTo.should.be.bignumber.equal(web3.utils.toBN(0))
        ])
    })

    it('sets previousChange correctly when revoking an attribute', async () => {
        await userRegistry.register(agent.name, agent.id, agent.publicKey)
        const setAttrResult = await userRegistry.setAttribute(agent.name, service.attrName, service.value, service.validity)
        const revokeAttrResult = await userRegistry.revokeAttribute(agent.name, service.attrName)

        return Promise.all([
            revokeAttrResult.logs[0].args.previousChange.should.be.bignumber.equal(web3.utils.toBN(setAttrResult.receipt.blockNumber))
        ])
    })
})
