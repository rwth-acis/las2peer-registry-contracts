const { BN } = require('./support/setup')

const UserRegistryContract = artifacts.require('UserRegistry')
const ServiceRegistryContract = artifacts.require('ServiceRegistry')

const service = {
    name: 'com.example.services.exampleService',
    nameHash: web3.utils.soliditySha3('com.example.services.exampleService'),
    className: 'ExampleService',
    hash: '0x50047cbf35f98cb1c7e46c24afa32078'
}

const author = {
    name: web3.utils.utf8ToHex('Alice'),
    nameAsHex: '0x416c696365000000000000000000000000000000000000000000000000000000', // in contrast to name this is not packed
    id: '0x1c4421af4d723edc834463c015a5b76ddce4cd679227e963c14941fcef2ee716bf8fbeabdce7a08ee2c261b16772b5bacbbca086746632b58d6658089c3fc480',
    publicKey: web3.utils.utf8ToHex('MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCqGKukO1De7zhZj6+H0qtjTkVxwTCpvKe4eCZ0FPqri0cb2JZfXJ/DgYSF6vUpwmJG8wVQZKjeGcjDOL5UlsuusFncCzWBQ7RKNUSesmQRMSGkVb1/3j+skZ6UtW+5u09lHNsj6tQ51s1SPrCBkedbNf0Tp0GbMJDyR4e9T04ZZwIDAQAB')
}

const doesntExist = 'some-name-that-does-not-exists'
const timestamp = '1542782753'
const nodeId = 'D48D38236745C04AA6B6700712C2972ACD0BDB0E'

contract('ServiceRegistryContract', accounts => {
    let userRegistry
    let serviceRegistry

    beforeEach(async () => {
        // I want to use `new`, but that's not possible because I can't access the UserRegistry address here, do I?
        userRegistry = await UserRegistryContract.new()
        serviceRegistry = await ServiceRegistryContract.new(userRegistry.address)
    })

    it('name is available', () =>
        (serviceRegistry.nameIsAvailable(service.name)).should.eventually.be.true
    )

    it('registration succeeds, but only if the username is known', async () => {
        await userRegistry.register(author.name, author.id, author.publicKey)

        return Promise.all([
            (serviceRegistry.register(service.name, author.name)).should.be.fulfilled,
            (serviceRegistry.register(service.name, doesntExist)).should.be.rejected
        ])
    })

    it('name is no longer available after it is registered', async () => {
        await userRegistry.register(author.name, author.id, author.publicKey)
        await serviceRegistry.register(service.name, author.name)
        return (serviceRegistry.nameIsAvailable(service.name)).should.eventually.be.false
    })

    it('service registration triggers event', async () => {
        await userRegistry.register(author.name, author.id, author.publicKey)
        return (serviceRegistry.register(service.name, author.name)).should.eventually.nested.include({
            'logs[0].event': 'ServiceCreated',
            'logs[0].args.nameHash': service.nameHash,
            'logs[0].args.author': author.nameAsHex
        })
    })

    it('release succeeds, but only if author owns service and sender owns author', async () => {
        await userRegistry.register(author.name, author.id, author.publicKey)
        await serviceRegistry.register(service.name, author.name)
        return Promise.all([
            (serviceRegistry.release(service.name, author.name, 1, 1, 1, service.hash)).should.be.fulfilled,
            (serviceRegistry.release(service.name, doesntExist, 1, 1, 1, service.hash)).should.be.rejected,
            (serviceRegistry.release(doesntExist, author.name, 1, 1, 1, service.hash)).should.be.rejected
        ])
    })

    it('release triggers event', async () => {
        await userRegistry.register(author.name, author.id, author.publicKey)
        await serviceRegistry.register(service.name, author.name)
        let result = await serviceRegistry.release(service.name, author.name, 1, 2, 3, service.hash)
        let logEntry = result.logs[0]

        logEntry.event.should.equal('ServiceReleased')
        logEntry.args.nameHash.should.equal(service.nameHash)
        logEntry.args.versionMajor.should.bignumber.equal(new BN(1))
        logEntry.args.versionMinor.should.bignumber.equal(new BN(2))
        logEntry.args.versionPatch.should.bignumber.equal(new BN(3))
    })

    // returning structs is problematic, see comments at bottom of ServiceRegistry.sol
    it('release can be accessed via public state variable')
    // async () => {
    //     await userRegistry.register(author.name, author.id, author.publicKey)
    //     await serviceRegistry.register(service.name, author.name)
    //     await serviceRegistry.release(service.name, author.name, 1, 2, 3, service.hash)
    //     // none of these are currently possible
    //     await serviceRegistry.service.nameToReleases()
    //     await serviceRegistry.service.nameToReleases(service.name)
    //     await serviceRegistry.getMapping()
    //     await serviceRegistry.getReleases(service.name)
    //     await serviceRegistry.getRelease(service.name, 0)
    //     assert(false)
    // }

    it('announcing deployment triggers event', async () => {
        await userRegistry.register(author.name, author.id, author.publicKey)
        await serviceRegistry.register(service.name, author.name)
        await serviceRegistry.release(service.name, author.name, 1, 2, 3, service.hash)

        let result = await serviceRegistry.announceDeployment(service.name, service.className, 1, 2, 3, timestamp, nodeId)
        let logEntry = result.logs[0]

        logEntry.event.should.equal('ServiceDeployment')
        logEntry.args.nameHash.should.equal(service.nameHash)
        logEntry.args.className.should.equal(service.className)
        logEntry.args.versionMajor.should.bignumber.equal(new BN(1))
        logEntry.args.versionMinor.should.bignumber.equal(new BN(2))
        logEntry.args.versionPatch.should.bignumber.equal(new BN(3))
        logEntry.args.timestamp.should.bignumber.equal(timestamp)
        logEntry.args.nodeId.should.equal(nodeId)
    })

    it('announcing deployment end triggers event', async () => {
        await userRegistry.register(author.name, author.id, author.publicKey)
        await serviceRegistry.register(service.name, author.name)
        await serviceRegistry.release(service.name, author.name, 1, 2, 3, service.hash)

        let result = await serviceRegistry.announceDeploymentEnd(service.name, service.className, 1, 2, 3, nodeId)
        let logEntry = result.logs[0]

        logEntry.event.should.equal('ServiceDeploymentEnd')
        logEntry.args.nameHash.should.equal(service.nameHash)
        logEntry.args.className.should.equal(service.className)
        logEntry.args.versionMajor.should.bignumber.equal(new BN(1))
        logEntry.args.versionMinor.should.bignumber.equal(new BN(2))
        logEntry.args.versionPatch.should.bignumber.equal(new BN(3))
        logEntry.args.nodeId.should.equal(nodeId)
    })
})
