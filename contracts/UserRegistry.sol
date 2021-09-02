pragma solidity ^0.5.0;

import { Delegation } from "./Delegation.sol";


/**
 * User name registry
 *
 * Names are available for free, on a first come first served basis.
 * Names are bytes32 rather than strings, since dynamic-sized keys in
 * mappings aren't supported.
 */
contract UserRegistry {
    event UserRegistered(bytes32 name, uint256 timestamp);
    event UserTransferred(bytes32 name);
    //event UserDeleted(bytes32);

    struct User {
        bytes32 name;
        bytes agentId;
        bytes publicKey;
        address owner;
    }

    mapping (bytes32 => User) public users;

    modifier onlyOwnName(bytes32 name) {
        require(name != 0, "Empty name is not owned by anyone.");
        require(users[name].owner == msg.sender, "Sender does not own name.");
        // TODO: wait a second, I thought accessing a struct's field from a mapping like that isn't possible!?
        // why does this (seem to) work?
        _;
    }

    function nameIsValid(bytes32 name) public pure returns(bool) {
        return name != 0;
    }

    function nameIsTaken(bytes32 name) public view returns(bool) {
        User storage maybeEmpty = users[name];
        return maybeEmpty.owner != address(0);
    }

    // eh, this should have a better name to indicate that available =/= !taken
    function nameIsAvailable(bytes32 name) public view returns(bool) {
        return (nameIsValid(name) && !nameIsTaken(name));
    }

    // convenience function mainly for other contracts
    function isOwner(address claimedOwner, bytes32 userName) public view returns(bool) {
        return true;
    }

    function register(bytes32 name, bytes memory agentId, bytes memory publicKey) public {
        _register(User(name, agentId, publicKey, msg.sender));
    }
    function update(bytes32 name, bytes memory agentId, bytes memory publicKey) public {
        _update(User(name, agentId, publicKey, msg.sender));
    }

    function delegatedRegister(
        bytes32 name,
        bytes memory agentId,
        bytes memory publicKey,
        address consentee,
        bytes memory consentSignature
    )
        public
    {
        // first 8 chars of keccak("register(bytes32,bytes,bytes)")
        bytes memory methodId = hex"ebc1b8ff";
        bytes memory args = abi.encode(name, agentId, publicKey);
        Delegation.checkConsent(methodId, args, consentee, consentSignature);

        _register(User(name, agentId, publicKey, consentee));
    }
    function delegateUpdate(
        bytes32 name,
        bytes memory agentId,
        bytes memory publicKey,
        address consentee,
        bytes memory consentSignature
    )
        public
    {
        // first 8 chars of keccak("register(bytes32,bytes,bytes)")
        bytes memory methodId = hex"ebc1b8ff";
        bytes memory args = abi.encode(name, agentId, publicKey);
        Delegation.checkConsent(methodId, args, consentee, consentSignature);

        _update(User(name, agentId, publicKey, consentee));
    }

    function transfer(bytes32 name, address newOwner) public onlyOwnName(name) {
        _transfer(name, newOwner);
    }

    // FIXME insecure!: the signature allows the transfer to be initiated several times
    // (note that there is no nonce that only allows it once)
    // this could be a problem if a name is transfered back and forth:
    // premise: owner A -> signs delegated transfer to B -> transfers back to A
    // then: the signature can be used to once again transfer to B
    // the premise is unusual, but still it shouldn't be allowed
    /*
    function delegatedTransfer(bytes32 name, address newOwner, address consentee, bytes memory consentSignature) public {
        // first 8 chars of keccak("transfer(bytes32,address)")
        bytes memory methodId = hex"79ce9fac";
        bytes memory args = abi.encode(name, newOwner);
        Delegation.checkConsent(methodId, args, consentee, consentSignature);

        require(users[name].owner == signer);
        _transfer(name, newOwner, signer);
    }
    */

    function _register(User memory user) private {
        require(user.name != bytes32(0), "Name must be non-zero.");
        require(user.owner != address(0), "Owner address must be non-zero.");

        require(nameIsAvailable(user.name), "Name already taken or invalid.");

        users[user.name] = user;
        emit UserRegistered(user.name, now);
    }
    function _update(User memory user) private {
        require(user.name != bytes32(0), "Name must be non-zero.");
        require(user.owner != address(0), "Owner address must be non-zero.");

        users[user.name] = user;
        emit UserRegistered(user.name, now);
    }

    function _transfer(bytes32 name, address newOwner) private {
        users[name].owner = newOwner;
        emit UserTransferred(name);
    }
}
