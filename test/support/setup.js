const BigNumber = web3.BigNumber

// careful: order matters, use chai-as-promised last. see
// https://github.com/domenic/chai-as-promised/issues/244
require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .use(require('chai-as-promised'))
    .should()
