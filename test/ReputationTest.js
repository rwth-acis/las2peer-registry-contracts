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

contract('ReputationContract', accounts => {
    let userRegistry
    let reputationRegistry

    beforeEach(async () => {
        userRegistry = await UserRegistryContract.new()
        reputationRegistry = await ReputationRegistryContract.new(userRegistry.address)
    })

    it('profile creation triggers UserProfileCreated event', async () => {
        // register Alice
        await userRegistry.register(alice.name, alice.id, alice.publicKey, { from: accounts[0] })
            .should.be.fulfilled
        // make Alice register her profile
        await reputationRegistry.createProfile(alice.name, { from: accounts[0] })
            .should.eventually.nested.include({
            'logs[0].event': 'UserProfileCreated',
            'logs[0].args.name': alice.nameAsHex,
            'logs[0].args.owner': accounts[0],
        })
    })

    it('profile creation initializes cumulative score and number of transactions to 0', async () => {
        // register Alice
        await userRegistry.register(alice.name, alice.id, alice.publicKey, { from: accounts[0] })
            .should.be.fulfilled
        // make Alice register her profile
        await reputationRegistry.createProfile(alice.name, { from: accounts[0] })
            .should.be.fulfilled

        var cumulativeScore = await reputationRegistry.getCumulativeScore.call(accounts[0]).valueOf();
        cumulativeScore.should.bignumber.equal(new BN(0));

        var noTransactions = await reputationRegistry.getNoTransactions.call(accounts[0]).valueOf();
        noTransactions.should.bignumber.equal(new BN(0));

    })

    it('profile creation only allowed to user owner', async () => {
        // register Alice and Bob
        await userRegistry.register(alice.name, alice.id, alice.publicKey, { from: accounts[0] })
            .should.be.fulfilled
        await userRegistry.register(bob.name, bob.id, bob.publicKey, { from: accounts[1] })
            .should.be.fulfilled

        // make Bob register Alice's profile and vice-versa
        await reputationRegistry.createProfile(bob.name, { from: accounts[0] })
            .should.be.rejected
        await reputationRegistry.createProfile(alice.name, { from: accounts[1] })
            .should.be.rejected

        // make them register their profiles
        await reputationRegistry.createProfile(alice.name, { from: accounts[0] })
            .should.be.fulfilled
        await reputationRegistry.createProfile(bob.name, { from: accounts[1] })
            .should.be.fulfilled
    })

    it('transaction triggers TransactionAdded event', async () => {
        // register Alice and Bob
        await userRegistry.register(alice.name, alice.id, alice.publicKey, { from: accounts[0] })
            .should.be.fulfilled
        await userRegistry.register(bob.name, bob.id, bob.publicKey, { from: accounts[1] })
            .should.be.fulfilled

        // make them register their profiles
        await (reputationRegistry.createProfile(alice.name, { from: accounts[0] }))
            .should.be.fulfilled
        await (reputationRegistry.createProfile(bob.name, { from: accounts[1] }))
            .should.be.fulfilled

        // add transaction, sender: A, receiver: B
        let result = await reputationRegistry.addTransaction(accounts[1], positiveTransactionAmount, { from: accounts[0] })
        let logEntry = result.logs[0]
        logEntry.event.should.equal('TransactionAdded')
        logEntry.args.sender
            .should.equal(accounts[0])
        logEntry.args.subject
            .should.equal(accounts[1])
    })

    it ('transaction updates reputation after call', async () => {
        // register Alice and Bob
        await userRegistry.register(alice.name, alice.id, alice.publicKey, { from: accounts[0] })
            .should.be.fulfilled
        await userRegistry.register(bob.name, bob.id, bob.publicKey, { from: accounts[1] })
            .should.be.fulfilled

        // make them register their profiles
        await (reputationRegistry.createProfile(alice.name, { from: accounts[0] }))
            .should.be.fulfilled
        await (reputationRegistry.createProfile(bob.name, { from: accounts[1] }))
            .should.be.fulfilled

         // assume they start with 0 reputation
         let score_before_A = await reputationRegistry.getCumulativeScore.call(accounts[0]);
         let noTrans_before_A = await reputationRegistry.getNoTransactions.call(accounts[0]);
         let score_before_B = await reputationRegistry.getCumulativeScore.call(accounts[1]);
         assert.equal(score_before_A.valueOf(), 0);
         assert.equal(noTrans_before_A.valueOf(), 0);
         assert.equal(score_before_B.valueOf(), 0);
 
         // add positive transaction, sender: A, receiver: B
         let result = await reputationRegistry.addTransaction(accounts[1], positiveTransactionAmount, { from: accounts[0] })
         let logEntry = result.logs[0]
         logEntry.event.should.equal('TransactionAdded')
         logEntry.args.sender
             .should.equal(accounts[0])
         logEntry.args.subject
             .should.equal(accounts[1])
         logEntry.args.grade
             .should.bignumber.equal(new BN(positiveTransactionAmount))
         logEntry.args.subjectNewScore
             .should.bignumber.equal(new BN(score_before_B + positiveTransactionAmount))
 
         // check their reputation after the transaction
         var score_after_A = await reputationRegistry.getCumulativeScore.call(accounts[0]).valueOf();
             score_after_A.should.bignumber.equal(new BN(0));

         var noTrans_after_B = await reputationRegistry.getNoTransactions.call(accounts[0]).valueOf();
             noTrans_after_B.should.bignumber.equal(new BN(noTrans_before_A + 1));

         var score_after_B = await reputationRegistry.getCumulativeScore.call(accounts[1]).valueOf();
             score_after_B.should.bignumber.equal(new BN(score_before_B + positiveTransactionAmount));

    })
})
