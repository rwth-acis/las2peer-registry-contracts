require('./support/setup.js')

const UserRegistryContract = artifacts.require('UserRegistry')
const ServiceRegistryContract = artifacts.require('ServiceRegistry')

const serviceName = 'com.example.services.exampleService'
const serviceNameHash = '0xf0093192310322844a7350f5e148a98c685e662693ef2997decaa71c489b7485' // web3.utils.soliditySha3(...) in web3 v1.x
const serviceClassName = 'ExampleService'
const authorName = 'Alice'
const authorNameAsHex = '0x416c696365000000000000000000000000000000000000000000000000000000' // web3.fromAscii('Alice', 64) // broken in web3 v0.2x.x
const authorAgentId = '1c4421af4d723edc834463c015a5b76ddce4cd679227e963c14941fcef2ee716bf8fbeabdce7a08ee2c261b16772b5bacbbca086746632b58d6658089c3fc480'
const doesNotExist = 'some-name-that-does-not-exists'
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
            'logs[0].args.nameHash': serviceNameHash,
            'logs[0].args.author': authorNameAsHex
        })
    })

    it('release succeeds, but only if author owns service and sender owns author', async () => {
        await userRegistry.register(authorName, authorAgentId)
        await serviceRegistry.register(serviceName, authorName)
        return Promise.all([
            (serviceRegistry.release(serviceName, authorName, 1, 1, 1, '')).should.be.fulfilled,
            (serviceRegistry.release(serviceName, doesNotExist, 1, 1, 1, '')).should.be.rejected,
            (serviceRegistry.release(doesNotExist, authorName, 1, 1, 1, '')).should.be.rejected
        ])
    })

    it('release triggers event', async () => {
        await userRegistry.register(authorName, authorAgentId)
        await serviceRegistry.register(serviceName, authorName)
        let result = await serviceRegistry.release(serviceName, authorName, 1, 2, 3, '')
        let logEntry = result.logs[0]

        logEntry.event.should.equal('ServiceReleased')
        logEntry.args.nameHash.should.equal(serviceNameHash)
        logEntry.args.versionMajor.should.bignumber.equal(1)
        logEntry.args.versionMinor.should.bignumber.equal(2)
        logEntry.args.versionPatch.should.bignumber.equal(3)
    })

    // returning structs is problematic, see comments at bottom of ServiceRegistry.sol
    it('release can be accessed via public state variable')
    // async () => {
    //     await userRegistry.register(authorName, authorAgentId)
    //     await serviceRegistry.register(serviceName, authorName)
    //     await serviceRegistry.release(serviceName, authorName, 1, 2, 3, '')
    //     // none of these are currently possible
    //     await serviceRegistry.serviceNameToReleases()
    //     await serviceRegistry.serviceNameToReleases(serviceName)
    //     await serviceRegistry.getMapping()
    //     await serviceRegistry.getReleases(serviceName)
    //     await serviceRegistry.getRelease(serviceName, 0)
    //     assert(false)
    // }

    it('announcing deployment triggers event', async () => {
        await userRegistry.register(authorName, authorAgentId)
        await serviceRegistry.register(serviceName, authorName)
        await serviceRegistry.release(serviceName, authorName, 1, 2, 3, '')

        let result = await serviceRegistry.announceDeployment(serviceName, serviceClassName, 1, 2, 3, timestamp, nodeId)
        let logEntry = result.logs[0]

        logEntry.event.should.equal('ServiceDeployment')
        logEntry.args.nameHash.should.equal(serviceNameHash)
        logEntry.args.className.should.equal(serviceClassName)
        logEntry.args.versionMajor.should.bignumber.equal(1)
        logEntry.args.versionMinor.should.bignumber.equal(2)
        logEntry.args.versionPatch.should.bignumber.equal(3)
        logEntry.args.timestamp.should.bignumber.equal(timestamp)
        logEntry.args.nodeId.should.equal(nodeId)
    })

    it('announcing deployment end triggers event', async () => {
        await userRegistry.register(authorName, authorAgentId)
        await serviceRegistry.register(serviceName, authorName)
        await serviceRegistry.release(serviceName, authorName, 1, 2, 3, '')

        let result = await serviceRegistry.announceDeploymentEnd(serviceName, serviceClassName, 1, 2, 3, nodeId)
        let logEntry = result.logs[0]

        logEntry.event.should.equal('ServiceDeploymentEnd')
        logEntry.args.nameHash.should.equal(serviceNameHash)
        logEntry.args.className.should.equal(serviceClassName)
        logEntry.args.versionMajor.should.bignumber.equal(1)
        logEntry.args.versionMinor.should.bignumber.equal(2)
        logEntry.args.versionPatch.should.bignumber.equal(3)
        logEntry.args.nodeId.should.equal(nodeId)
    })
})
