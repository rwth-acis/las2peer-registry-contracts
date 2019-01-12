require('./support/setup')

const CommunityTagIndexContract = artifacts.require('CommunityTagIndex')

const tag = web3.utils.utf8ToHex('some-tag')
const text = 'lorem ipsum dolor sit amet'

contract('CommunityTagIndexContract', accounts => {
    let communityTagIndex

    beforeEach(async () => {
        communityTagIndex = await CommunityTagIndexContract.new()
    })

    it('unused tag is available', () =>
        (communityTagIndex.isAvailable(tag)).should.eventually.be.true
    )

    it('tag can be created', () =>
        (communityTagIndex.create(tag, text)).should.be.fulfilled
    )

    it('created tag is no longer available, can be viewed', async () => {
        let creationResult = await (communityTagIndex.create(tag, text))

        return Promise.all([
            creationResult.should.nested.include({
                'logs[0].event': 'CommunityTagCreated',
                'logs[0].args.name': '0x736f6d652d746167000000000000000000000000000000000000000000000000' // web3.fromAscii(tag, 64) // broken in web3 v0.2x.x
            }),
            (communityTagIndex.isAvailable(tag)).should.eventually.be.false,
            (communityTagIndex.viewDescription(tag)).should.eventually.equal(text)
        ])
    })
})
