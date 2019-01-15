const { BN } = require('./support/setup')

const DelegationExample = artifacts.require('DelegationExample')

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

contract('DelegationTest', accounts => {
    let delegationExample

    beforeEach(async () => {
        delegationExample = await DelegationExample.new()
    })

    it('direct call works', () => delegationExample.testFunction(new BN(5), "foo").should.eventually.bignumber.equal(new BN(42)))

    it('delegated call signed with encodeFunctionCall and manual ABI works', () => {
        let data = web3.eth.abi.encodeFunctionCall({
            name: 'testFunction',
            type: 'function',
            inputs: [
                { type: 'uint256', name: 'a' },
                { type: 'string', name: 'b' }
            ]
        }, [5, "foo"])

        let dataHash = web3.utils.sha3(data)
        let sigData = web3.eth.accounts.sign(dataHash, credentials[1].privateKey)
        return delegationExample.delegatedTestFunction(new BN(5), "foo", credentials[1].account, sigData.signature).should.eventually.bignumber.equal(new BN(42))
    })

    it('delegated call signed with encodeFunctionCall and generated ABI works', () => {
        let abi = DelegationExample.abi.filter((o) => o.name === 'testFunction')[0]
        let data = web3.eth.abi.encodeFunctionCall(abi, [5, "foo"])

        let dataHash = web3.utils.sha3(data)
        let sigData = web3.eth.accounts.sign(dataHash, credentials[1].privateKey)
        return delegationExample.delegatedTestFunction(new BN(5), "foo", credentials[1].account, sigData.signature).should.eventually.bignumber.equal(new BN(42))
    })
})
