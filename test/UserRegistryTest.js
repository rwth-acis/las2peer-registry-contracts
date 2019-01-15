const { BN } = require('./support/setup')

const UserRegistryContract = artifacts.require('UserRegistry')
const Delegation = artifacts.require('Delegation')

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

// accounts for 'differ employ cook sport clinic wedding melody column pave stuff oak price'
const credentials = [
    {
        account: '0xee5e18b0963126cde89dd2b826f0acdb7e71acdb',
        privateKey: '0x964d02d3f440a078af46dbc459fc2ac7674e715903fd9f20df737ce26f8bd368'
    },
    {
        account: '0x4d341f10a9bdd3ffb1a4e0c5ddea857c7f885a42',
        privateKey: '0x6129ae2b6bfbae676f66e624495812394ecb22b8e0c1475366f58c2a29ed8a81'
    },
    {
        account: '0xf783235afa5f7405a0914a95a154e5277650d570',
        privateKey: '0x6c667bf7a3ac9c55e6d3c4f02d2eab7e139bfbdbb59cc5d9533436c8b7a4331a'
    }
]

contract('UserRegistryContract', accounts => {
    let userRegistry

    beforeEach(async () => {
        // using new to reset state, see
        // https://github.com/trufflesuite/truffle/issues/727
        // and in general
        // https://stackoverflow.com/questions/29508444/why-should-mocha-test-cases-be-stateless
        userRegistry = await UserRegistryContract.new()
    })

    it('DEBUG direct call', () => userRegistry.debug(new BN(5)).should.eventually.bignumber.equal(new BN(8)))

    it('DEBUG signed with encodeFunctionCall and manual ABI', () => {
        let data = web3.eth.abi.encodeFunctionCall({
            name: 'debug',
            type: 'function',
            inputs: [{ type: 'uint256', name: 'a' }]
        }, [5])
        let dataHash = web3.utils.sha3(data)
        let sigData = web3.eth.accounts.sign(dataHash, credentials[2].privateKey)
        return userRegistry.delegatedDebug(new BN(5), credentials[2].account, sigData.signature).should.eventually.bignumber.equal(new BN(8))
    })

    it('DEBUG signed with encodeFunctionCall and generated ABI', () => {
        let abi = UserRegistryContract.abi.filter((o) => o.name === 'debug')[0]
        let data = web3.eth.abi.encodeFunctionCall(abi, [5])
        let sigData = web3.eth.accounts.sign(data, credentials[2].privateKey)
        userRegistry.delegatedDebug(new BN(5), credentials[2].account, sigData.signature).should.eventually.bignumber.equal(new BN(8))
    })
})
