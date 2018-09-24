pragma solidity ^0.4.24;

// random caveats:
// - `migrate --reset` is definitely needed, `migrate` messes up


contract HelloWorld {
    uint public memberVar;

    event SimpleEvent(uint);

    function noop(uint v) public {
    }

    function unmarkedPureF(uint v) public returns(uint) {
        return v;
    }

    function pureF(uint v) public pure returns(uint) {
        return v;
    }

    function viewF(uint v) public view returns(uint) {
        return memberVar;
    }

    function setterF(uint v) public {
        memberVar = v;
    }

    // fails: HelloWorld.deployed().then(i => i.emitEvent(3))
    // shows returns: HelloWorld.deployed().then(i => i.emitEvent.call(3))
    function emitEvent(uint v) public {
        emit SimpleEvent(v);
    }

    // same
    function emitAndReturn(uint v) public returns(uint) {
        emit SimpleEvent(v);
        return v;
    }

    // truffle only accepts one of them, and the order of declaration does not matter
    // (in this case it is always the uint256 version
    function overloaded(uint v) public returns(uint) {
        emit SimpleEvent(42);
        return 42;
    }

    // this works: HelloWorld.deployed().then(i => i.contract.overloaded['bool'].call(true))
    // also works, returns tx hash:  HelloWorld.deployed().then(i => i.contract.overloaded['bool'](true, {from: '0xc6932a3a7bcdc546284ceea8295b63e4d1d55500', gas: 50000}))
    function overloaded(bool v) public returns(uint) {
        emit SimpleEvent(23);
        return 23;
    }
}
