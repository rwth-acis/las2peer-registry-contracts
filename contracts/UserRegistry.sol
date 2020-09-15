pragma solidity >= 0.5.0 <= 0.7.0;

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

    event DIDAttributeChanged(
        bytes32 userName,
        bytes32 attrName,
        bytes value, // Not JSON, but custom, more efficient encoding
        uint validTo, // Used to limit time or invalidate attribute
        uint previousChange // Used to query all change events
    );

    struct User {
        bytes32 name;
        bytes agentId;
        bytes publicKey;
        address owner;
    }

    mapping (bytes32 => User) public users;

    // Number of the block where the last change to event-based storage of a user (by name) occured.
    mapping (bytes32 => uint) changed;

    // Nonce to prevent replay attacks (mapped by owner)
    // Owner needs to include nonce in signature
    mapping (address => uint) nonce;

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
        return users[userName].owner == claimedOwner;
    }

    // onlyOwner is the modifier version of isOwner
    modifier onlyOwner(address claimedOwner, bytes32 userName) {
        require(isOwner(claimedOwner, userName));

        _;
    }

    function register(bytes32 name, bytes memory agentId, bytes memory publicKey) public {
        _register(User(name, agentId, publicKey, msg.sender));
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

    function _transfer(bytes32 name, address newOwner) private {
        users[name].owner = newOwner;
        emit UserTransferred(name);
    }

    // _setAttribute adds an DID attribute to a user.
    // It references the block of the last change to the user's attributes.
    // This allows us to quickly iterate over a user's change events to build the attribute objects.
    //
    // Existence of user verified by onlyOwner
    function _setAttribute(
        bytes32 userName,
        address actor,
        bytes32 attrName,
        bytes memory value,
        uint validity
    ) internal onlyOwner(actor, userName) {
        emit DIDAttributeChanged(userName, attrName, value, now + validity, changed[userName]);
        changed[userName] = block.number;
    }

    function setAttribute(
        bytes32 userName,
        bytes32 attrName,
        bytes memory value,
        uint validity
    ) public {
        _setAttribute(userName, msg.sender, attrName, value, validity);
    }

    function delegatedSetAttribute(
        bytes32 userName,
        bytes32 attrName,
        bytes memory value,
        uint validity,
        address consentee,
        bytes memory consentSignature
    ) public onlyOwner(consentee, userName) {
        // first 8 chars of keccak("setAttribute(bytes32,bytes32,bytes,uint)")
        bytes memory methodId = hex"5516e043";
        bytes memory args = abi.encode(userName, attrName, value, validity, nonce[consentee]);
        Delegation.checkConsent(methodId, args, consentee, consentSignature);
        nonce[consentee]++;

        _setAttribute(userName, consentee, attrName, value, validity);
    }

    // _revokeAttribute revokes an attribute by setting its validTo to 0
    // Cannot "remove" an attribute since it was written to the blockchain.
    // Wording chosen to avoid confusion.
    function _revokeAttribute(
        bytes32 userName,
        address actor,
        bytes32 attrName,
        bytes memory value
    ) internal onlyOwner(actor, userName) {
        emit DIDAttributeChanged(userName, attrName, value, 0, changed[userName]);
        changed[userName] = block.number;
    }

    function revokeAttribute(bytes32 userName, bytes32 attrName, bytes memory value) public {
        _revokeAttribute(userName, msg.sender, attrName, value);
    }

    function delegatedRevokeAttribute(
        bytes32 userName,
        bytes32 attrName,
        bytes memory value,
        address consentee,
        bytes memory consentSignature
    ) public {
        // first 8 chars of keccak("revokeAttribute(bytes32,bytes32,bytes)")
        bytes memory methodId = hex"80f9a59d";
        bytes memory args = abi.encode(userName, attrName, value, nonce[consentee]);
        Delegation.checkConsent(methodId, args, consentee, consentSignature);
        nonce[consentee]++;

        _revokeAttribute(userName, consentee, attrName, value);
    }
}
