const BN = web3.utils.BN

const chai = require('chai')

// careful: order matters, use chai-as-promised last. see
// https://github.com/domenic/chai-as-promised/issues/244
require('chai')
const should = chai
    .use(require('chai-bn')(BN))
    .use(require('chai-as-promised'))
    .should()

module.exports = {
    BN,
    expect: chai.expect,
    should
}
