require('./support/setup.js')

const UserRegistryContract = artifacts.require('UserRegistry')
const ServiceRegistryContract = artifacts.require('ServiceRegistry')

const serviceName = 'SampleService'
const authorName = 'Alice'
const authorAgentId = 'an-agent-id'
const doesNotExist = 'some-name-that-does-not-exists'

contract('ServiceRegistryContract', accounts => {
    let userRegistry
    let serviceRegistry

    beforeEach(async () => {
        // I want to use `new`, but that's not possible because I can't access the UserRegistry address here, do I?
        userRegistry = await UserRegistryContract.new()
        serviceRegistry = await ServiceRegistryContract.new(userRegistry.address)
    })

    it('name is available', () =>
        (serviceRegistry.nameIsAvailable(serviceName)).should.eventually.be.true
    )

    it('registration succeeds, but only if the username is known', async () => {
        await userRegistry.register(authorName, authorAgentId)

        return Promise.all([
            (serviceRegistry.register(serviceName, authorName)).should.be.fulfilled,
            (serviceRegistry.register(serviceName, doesNotExist)).should.be.rejected
        ])
    })

    it('name is no longer available after it is registered', async () => {
        await userRegistry.register(authorName, authorAgentId)
        await serviceRegistry.register(serviceName, authorName)
        return (serviceRegistry.nameIsAvailable(serviceName)).should.eventually.be.false
    })

    it('service registration triggers event', async () => {
        await userRegistry.register(authorName, authorAgentId)
        return (serviceRegistry.register(serviceName, authorName)).should.eventually.nested.include({
            'logs[0].event': 'ServiceCreated',
            'logs[0].args.nameHash': '0x0937837eb6fb8dcd19b18001fc84b3e836c92f4be94a8a280dd688d5dee5e823', // web3.utils.soliditySha3('SampleService')
            'logs[0].args.author': '0x416c696365000000000000000000000000000000000000000000000000000000' // web3.fromAscii('Alice', 64) // broken in web3 v0.2x.x
        })
    })

    it('release succeeds, but only if author owns service and sender owns author', async () => {
        await userRegistry.register(authorName, authorAgentId)
        await serviceRegistry.register(serviceName, authorName)
        return Promise.all([
            (serviceRegistry.release(serviceName, authorName, 1, 1, 1)).should.be.fulfilled,
            (serviceRegistry.release(serviceName, doesNotExist, 1, 1, 1)).should.be.rejected,
            (serviceRegistry.release(doesNotExist, authorName, 1, 1, 1)).should.be.rejected
        ])
    })

    it('release triggers event', async () => {
        await userRegistry.register(authorName, authorAgentId)
        await serviceRegistry.register(serviceName, authorName)
        let result = await serviceRegistry.release(serviceName, authorName, 1, 2, 3)
        let logEntry = result.logs[0]

        logEntry.event.should.equal('ServiceReleased')
        logEntry.args.nameHash.should.equal('0x0937837eb6fb8dcd19b18001fc84b3e836c92f4be94a8a280dd688d5dee5e823') // web3.fromAscii('SampleService', 64) // broken in web3 v0.2x.x
        logEntry.args.versionMajor.should.bignumber.equal(1)
        logEntry.args.versionMinor.should.bignumber.equal(2)
        logEntry.args.versionPatch.should.bignumber.equal(3)
    })

    // returning structs is problematic, see comments at bottom of ServiceRegistry.sol
    it('release can be accessed via public state variable')
    // async () => {
    //     await userRegistry.register(authorName, authorAgentId)
    //     await serviceRegistry.register(serviceName, authorName)
    //     await serviceRegistry.release(serviceName, authorName, 1, 2, 3)
    //     // none of are currently possible
    //     await serviceRegistry.serviceNameToReleases()
    //     await serviceRegistry.serviceNameToReleases(serviceName)
    //     await serviceRegistry.getMapping()
    //     await serviceRegistry.getReleases(serviceName)
    //     await serviceRegistry.getRelease(serviceName, 0)
    //     assert(false)
    // }
})
