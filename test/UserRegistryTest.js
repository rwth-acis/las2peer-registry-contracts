const { BN } = require('./support/setup')

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

    it('DEBUG signed with encodeFunctionCall and manual ABI', () => {
        let data = web3.eth.abi.encodeFunctionCall({
            name: 'debug',
            type: 'function',
            inputs: [{ type: 'uint256', name: 'a' }]
        }, [5])
        let sigData = web3.eth.accounts.sign(data, credentials[2].privateKey)
        userRegistry.delegatedDebug(new BN(5), credentials[2].account, sigData.signature).should.eventually.bignumber.equal(new BN(8))
    })

    it('DEBUG signed with encodeFunctionCall and generated ABI', () => {
        let abi = userRegistry.abi.filter((o) => o.name === 'debug')[0]
        let data = web3.eth.abi.encodeFunctionCall(abi, [5])
        let sigData = web3.eth.accounts.sign(data, credentials[1].privateKey)
        userRegistry.delegatedDebug(new BN(5), credentials[1].account, sigData.signature).should.eventually.bignumber.equal(new BN(8))
    })

//  it('DEBUG', () => {
//      userRegistry.debug(new BN(5)).should.eventually.bignumber.equal(new BN(8))
//  })

//  it('empty (byte NULL) name is invalid', () =>
//      userRegistry.nameIsValid('0x0').should.eventually.be.false
//  )

//  it('example name is valid', () =>
//      userRegistry.nameIsValid(agent.name).should.eventually.be.true
//  )

//  it('example name is not taken', () =>
//      userRegistry.nameIsTaken(agent.name).should.eventually.be.false
//  )

//  it('registration is possible, emits event, and makes name taken/unavailable', async () => {
//      let registrationResult = await userRegistry.register(agent.name, agent.id, agent.publicKey)

//      return Promise.all([
//          registrationResult.should.nested.include({
//              'logs[0].event': 'UserRegistered',
//              'logs[0].args.name': '0x416c696365000000000000000000000000000000000000000000000000000000' // web3.fromAscii(agent.name, 64) // broken in web3 v0.2x.x
//          }),
//          userRegistry.nameIsTaken(agent.name).should.eventually.be.true,
//          userRegistry.nameIsAvailable(agent.name).should.eventually.be.false,
//          userRegistry.isOwner(accounts[0], agent.name).should.eventually.be.true,
//          userRegistry.isOwner(accounts[1], agent.name).should.eventually.be.false
//      ])
//  })

//  it('registration with duplicate name is not possible', async () => {
//      await userRegistry.register(agent.name, agent.id, agent.publicKey)
//      return userRegistry.register(agent.name, agent.id, agent.publicKey).should.be.rejected
//  })

//  it('delegated registration with signature of some other account correctly reflects ownership', async () => {
//      let data = web3.eth.abi.encodeFunctionCall(userRegistry.abi[7], [agent.name, agent.id, agent.publicKey])
//      let dataHash = web3.utils.soliditySha3(data)
//      let signature = web3.eth.accounts.sign(dataHash, credentials[0].privateKey).signature

//      let res = await userRegistry.debug(dataHash, signature)
//      let exp = web3.eth.accounts.recover(dataHash, signature)

//      let foo

//      /*
//      bytes memory mid = hex"ebc1b8ff"

//      bytes memory id = hex"1c4421af4d723edc834463c015a5b76ddce4cd679227e963c14941fcef2ee716bf8fbeabdce7a08ee2c261b16772b5bacbbca086746632b58d6658089c3fc480"

//      bytes32 name =  0x416c696365
//      OR
//      bytes32 name = 0x416c696365000000000000000000000000000000000000000000000000000000

//      bytes memory pk = hex"4d4947664d413047435371475349623344514542415155414134474e4144434269514b4267514371474b756b4f314465377a685a6a362b483071746a546b567877544370764b653465435a304650717269306362324a5a66584a2f446759534636765570776d4a47387756515a4b6a6547636a444f4c35556c73757573466e63437a57425137524b4e555365736d51524d53476b5662312f336a2b736b5a365574572b357530396c484e736a3674513531733153507243426b6564624e663054703047624d4a4479523465395430345a5a77494441514142"

//      abi.encode(mid, name, id, pk)
//      0x0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000416c69636500000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000004ebc1b8ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401c4421af4d723edc834463c015a5b76ddce4cd679227e963c14941fcef2ee716bf8fbeabdce7a08ee2c261b16772b5bacbbca086746632b58d6658089c3fc48000000000000000000000000000000000000000000000000000000000000000d84d4947664d413047435371475349623344514542415155414134474e4144434269514b4267514371474b756b4f314465377a685a6a362b483071746a546b567877544370764b653465435a304650717269306362324a5a66584a2f446759534636765570776d4a47387756515a4b6a6547636a444f4c35556c73757573466e63437a57425137524b4e555365736d51524d53476b5662312f336a2b736b5a365574572b357530396c484e736a3674513531733153507243426b6564624e663054703047624d4a4479523465395430345a5a774944415141420000000000000000
//      expected:                                                                                                    0xebc1b8ff 416c696365000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000                                                                          401c4421af4d723edc834463c015a5b76ddce4cd679227e963c14941fcef2ee716bf8fbeabdce7a08ee2c261b16772b5bacbbca086746632b58d6658089c3fc48000000000000000000000000000000000000000000000000000000000000000d84d4947664d413047435371475349623344514542415155414134474e4144434269514b4267514371474b756b4f314465377a685a6a362b483071746a546b567877544370764b653465435a304650717269306362324a5a66584a2f446759534636765570776d4a47387756515a4b6a6547636a444f4c35556c73757573466e63437a57425137524b4e555365736d51524d53476b5662312f336a2b736b5a365574572b357530396c484e736a3674513531733153507243426b6564624e663054703047624d4a4479523465395430345a5a774944415141420000000000000000
//                                                                                                           0xebc1b8ff 000000000000000000000000000000000000000000000000000000416c696365                                                                                                                                                                                                                                                                          1c4421af4d723edc834463c015a5b76ddce4cd679227e963c14941fcef2ee716bf8fbeabdce7a08ee2c261b16772b5bacbbca086746632b58d6658089c3fc48                                                                04d4947664d413047435371475349623344514542415155414134474e4144434269514b4267514371474b756b4f314465377a685a6a362b483071746a546b567877544370764b653465435a304650717269306362324a5a66584a2f446759534636765570776d4a47387756515a4b6a6547636a444f4c35556c73757573466e63437a57425137524b4e555365736d51524d53476b5662312f336a2b736b5a365574572b357530396c484e736a3674513531733153507243426b6564624e663054703047624d4a4479523465395430345a5a77494441514142
//      -----------

//      let sigDetail = web3.eth.accounts.sign(dataHash, credentials[0].privateKey)
//      let otherSign = await web3.eth.sign(dataHash, accounts[0])
//      let reverse = web3.eth.accounts.recover(sigDetail)

//      await userRegistry.delegatedRegister(agent.name, agent.id, agent.publicKey, otherSign)

//      let owner = (await userRegistry.users(agent.name)).owner // DEBUG

//      // FIXME: okay, so the signature is apparently valid but does not belong to the account we expected:
//      // it's [0]: 0x0a3e4c1A7CD0dEb7eB284F678C732C4BCA3d6334
//      //      [1]: 0xf5470A799D86E4D7e204aD8d16f52bb7d4d48aBb
//      //      [2]: 0x9160F1D6637f2d4c1fDb1aA2a51F2247323B853C
//      // expected 0x4d341f10a9bdd3ffb1a4e0c5ddea857c7f885a42
//      // my first guess is that the private key format / encoding is wrong
//      // but web3.eth.accounts.privateKeyToAccount(credentials.privateKey) yields expected

//      return Promise.all([
//          userRegistry.nameIsTaken(agent.name).should.eventually.be.true,
//          userRegistry.isOwner(credentials[0].account, agent.name).should.eventually.be.true,
//          userRegistry.isOwner(accounts[0], agent.name).should.eventually.be.false
//      ])
//      */
//  })

//  it('name can be transferred', async function () {
//      if (accounts.length < 2) {
//          this.skip()
//      }

//      await userRegistry.register(agent.name, agent.id, agent.publicKey, { from: accounts[0] })
//      let transferResult = await userRegistry.transfer(agent.name, accounts[1])
//      return Promise.all([
//          transferResult.should.nested.include({
//              'logs[0].event': 'UserTransferred',
//              'logs[0].args.name': '0x416c696365000000000000000000000000000000000000000000000000000000' // web3.fromAscii(agent.name, 64) // broken
//          })
//      ])
//  })
})
