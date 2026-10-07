const { BN } = require('./support/setup')

const UserRegistryContract = artifacts.require('UserRegistry')
const ReputationRegistryContract = artifacts.require('ReputationRegistry')


const alice = {
    name: web3.utils.utf8ToHex('Alice'),
    nameAsHex: '0x416c696365000000000000000000000000000000000000000000000000000000', // in contrast to name this is not packed
    id: '0x1c4421af4d723edc834463c015a5b76ddce4cd679227e963c14941fcef2ee716bf8fbeabdce7a08ee2c261b16772b5bacbbca086746632b58d6658089c3fc480',
    publicKey: web3.utils.utf8ToHex('MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCqGKukO1De7zhZj6+H0qtjTkVxwTCpvKe4eCZ0FPqri0cb2JZfXJ/DgYSF6vUpwmJG8wVQZKjeGcjDOL5UlsuusFncCzWBQ7RKNUSesmQRMSGkVb1/3j+skZ6UtW+5u09lHNsj6tQ51s1SPrCBkedbNf0Tp0GbMJDyR4e9T04ZZwIDAQAB')
}

const bob = {
    name: web3.utils.utf8ToHex('Bob'),
    nameAsHex: '0x426f620000000000000000000000000000000000000000000000000000000000', // in contrast to name this is not packed
    id: '0x4ef8844d7c3b6964a9071b680b0bf6438deec50dc1c361cac2d112126a7eaaf7bef7876e8250a62e66d31c7b385b7ced2424f5e4c9e432461c79bc5bcdf86b2c',
    publicKey: web3.utils.utf8ToHex('RISJ1Ee6KZVMrS/DjDBZxDfn4B8Xt6UdTCCBN+DGluGQRGv2kMePQq7pFtCGk7KsSAAqQ3GmsZVJKGcU0ODUybbzCJBm0pWjOfl0w0NMVshC0eDJWR60Q0AZwuFQvsTbTjLt5AMNe1f9Cc+zG3pK4ZNbGUTIeH14SSgwS4AC6QD0QkkcseAHjZuIGu5eq1Qs5B9wUFgb+qiYQPB/rjKZAijk')
}

const positiveTransactionAmount =  3;
const negativeTransactionAmount = -3;

const timestamp = 1600000000

contract('ReputationContract', accounts => {
    let userRegistry
    let reputationRegistry

    beforeEach(async () => {
        userRegistry = await UserRegistryContract.new()
        reputationRegistry = await ReputationRegistryContract.new(userRegistry.address)
    })

    async function registerAliceAndBob () {
        await userRegistry.register(alice.name, alice.id, alice.publicKey, { from: accounts[0] })
            .should.be.fulfilled
        await userRegistry.register(bob.name, bob.id, bob.publicKey, { from: accounts[1] })
            .should.be.fulfilled
        await reputationRegistry.createProfile(accounts[0], alice.name, { from: accounts[0] })
            .should.be.fulfilled
        await reputationRegistry.createProfile(accounts[1], bob.name, { from: accounts[1] })
            .should.be.fulfilled
    }

    it('profile creation triggers UserProfileCreated event', async () => {
        await userRegistry.register(alice.name, alice.id, alice.publicKey, { from: accounts[0] })
            .should.be.fulfilled
        await reputationRegistry.createProfile(accounts[0], alice.name, { from: accounts[0] })
            .should.eventually.nested.include({
                'logs[0].event': 'UserProfileCreated',
                'logs[0].args.name': alice.nameAsHex,
                'logs[0].args.owner': accounts[0]
            })
    })

    it('profile creation initializes cumulative score and number of transactions to 0', async () => {
        await userRegistry.register(alice.name, alice.id, alice.publicKey, { from: accounts[0] })
            .should.be.fulfilled
        await reputationRegistry.createProfile(accounts[0], alice.name, { from: accounts[0] })
            .should.be.fulfilled

        ;(await reputationRegistry.hasProfile(accounts[0])).should.equal(true)
        ;(await reputationRegistry.getCumulativeScore(accounts[0])).should.bignumber.equal(new BN(0))
        ;(await reputationRegistry.getNoTransactionsSent(accounts[0])).should.bignumber.equal(new BN(0))
        ;(await reputationRegistry.getNoTransactionsReceived(accounts[0])).should.bignumber.equal(new BN(0))
    })

    it('profile cannot be created twice', async () => {
        await reputationRegistry.createProfile(accounts[0], alice.name, { from: accounts[0] })
            .should.be.fulfilled
        await reputationRegistry.createProfile(accounts[0], alice.name, { from: accounts[0] })
            .should.be.rejected
    })

    // Known gap: since cb267ed (2020) createProfile takes the owner address as a parameter
    // instead of using msg.sender, so anyone can create a profile for any address.
    // las2peer only ever sends it from the agent's own account. See ROADMAP.md (security).
    it.skip('profile creation only allowed to the address owner', async () => {
        await reputationRegistry.createProfile(accounts[0], alice.name, { from: accounts[1] })
            .should.be.rejected
    })

    it('transaction triggers TransactionAdded event', async () => {
        await registerAliceAndBob()

        const result = await reputationRegistry.addTransaction(accounts[1], positiveTransactionAmount, timestamp,
            { from: accounts[0] })
        const logEntry = result.logs.find(log => log.event === 'TransactionAdded')
        logEntry.args.sender.should.equal(accounts[0])
        logEntry.args.recipient.should.equal(accounts[1])
        logEntry.args.grade.should.bignumber.equal(new BN(positiveTransactionAmount))
    })

    it('transaction updates reputation and counters', async () => {
        await registerAliceAndBob()

        await reputationRegistry.addTransaction(accounts[1], positiveTransactionAmount, timestamp, { from: accounts[0] })
            .should.be.fulfilled

        ;(await reputationRegistry.getCumulativeScore(accounts[0])).should.bignumber.equal(new BN(0))
        ;(await reputationRegistry.getCumulativeScore(accounts[1])).should.bignumber.equal(new BN(positiveTransactionAmount))
        ;(await reputationRegistry.getNoTransactionsSent(accounts[0])).should.bignumber.equal(new BN(1))
        ;(await reputationRegistry.getNoTransactionsReceived(accounts[1])).should.bignumber.equal(new BN(1))

        await reputationRegistry.addTransaction(accounts[1], 0, timestamp + 1, { from: accounts[0] })
            .should.be.fulfilled
        ;(await reputationRegistry.getCumulativeScore(accounts[1])).should.bignumber.equal(new BN(positiveTransactionAmount))
        ;(await reputationRegistry.getNoTransactionsReceived(accounts[1])).should.bignumber.equal(new BN(2))
    })

    it('rating yourself is rejected', async () => {
        await registerAliceAndBob()
        await reputationRegistry.addTransaction(accounts[0], positiveTransactionAmount, timestamp, { from: accounts[0] })
            .should.be.rejected
    })

    it('rating without a profile is rejected', async () => {
        await reputationRegistry.createProfile(accounts[1], bob.name, { from: accounts[1] })
            .should.be.fulfilled
        await reputationRegistry.addTransaction(accounts[1], positiveTransactionAmount, timestamp, { from: accounts[2] })
            .should.be.rejected
    })

    it('rating outside the allowed range (0-5) is rejected', async () => {
        await registerAliceAndBob()
        await reputationRegistry.addTransaction(accounts[1], negativeTransactionAmount, timestamp, { from: accounts[0] })
            .should.be.rejected
        await reputationRegistry.addTransaction(accounts[1], 1000, timestamp, { from: accounts[0] })
            .should.be.rejected
        await reputationRegistry.addTransaction(accounts[1], -1000, timestamp, { from: accounts[0] })
            .should.be.rejected
    })
})
