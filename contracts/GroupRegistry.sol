pragma solidity ^0.5.0;

import { Delegation } from "./Delegation.sol";


/**
 * Group name registry
 *
 * GroupNames are available for free, on a first come first served basis.
 * GrouNames are bytes32 rather than strings, since dynamic-sized keys in
 * mappings aren't supported.
 */
contract GroupRegistry {
    event GroupRegistered(bytes32 name, uint256 timestamp);
    event GroupTransferred(bytes32 name);
    //event GroupDeleted(bytes32);

    struct Group {
        bytes32 name;
        bytes agentId;
        bytes publicKey;
        address owner;
    }

    mapping (bytes32 => Group) public groups;

    modifier onlyOwnName(bytes32 name) {
        require(name != 0, "Empty name is not owned by anyone.");
        require(groups[name].owner == msg.sender, "Sender does not own name.");
        // TODO: wait a second, I thought accessing a struct's field from a mapping like that isn't possible!?
        // why does this (seem to) work?
        _;
    }

    function groupNameIsValid(bytes32 name) public pure returns(bool) {
        return name != 0;
    }

    function nameIsTaken(bytes32 name) public view returns(bool) {
        Group storage maybeEmpty = groups[name];
        return maybeEmpty.owner != address(0);
    }

    // eh, this should have a better name to indicate that available =/= !taken
    function groupNameIsAvailable(bytes32 name) public view returns(bool) {
        return (groupNameIsValid(name) && !nameIsTaken(name));
    }

    // convenience function mainly for other contracts
    function isOwner(address claimedOwner, bytes32 groupName) public view returns(bool) {
        return groups[groupName].owner == claimedOwner;
    }

    function register(bytes32 name, bytes memory agentId, bytes memory publicKey) public {
        _register(Group(name, agentId, publicKey, msg.sender));
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

        _register(Group(name, agentId, publicKey, consentee));
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

        require(groups[name].owner == signer);
        _transfer(name, newOwner, signer);
    }
    */

    function _register(Group memory group) private {
        require(group.name != bytes32(0), "Name must be non-zero.");
        require(group.owner != address(0), "Owner address must be non-zero.");

        require(groupNameIsAvailable(group.name), "Name already taken or invalid.");

        groups[group.name] = group;
        emit GroupRegistered(group.name, now);
    }

    function _transfer(bytes32 name, address newOwner) private {
        groups[name].owner = newOwner;
        emit GroupTransferred(name);
    }
}
