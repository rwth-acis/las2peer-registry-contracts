pragma solidity ^0.4.24;


/**
 * User name registry
 *
 * Names are available for free, on a first come first served basis.
 * Names are bytes32 rather than strings, since dynamic-sized keys in
 * mappings aren't supported.
 */
contract UserRegistry {
    function debug() pure returns(bool) {
        return true;
    }


    event UserRegistered(bytes32);
    event UserTransfered(bytes32);
    //event UserDeleted(bytes32);

    struct User {
        bytes32 name;
        bytes agentId; // 64 bytes?
        address owner;
        bytes dhtSupplement; // TODO: devise storage format
    }

    mapping (bytes32 => User) public users;

    modifier onlyOwnName(bytes32 name) {
        require(name != 0, "Empty name is not owned by anyone.");
        require(users[name].owner == msg.sender, "Sender does not own name.");
        _;
    }

    function nameIsAvailable(bytes32 name) public view returns(bool) {
        //return (users[name] == 0); // not possible since User is a struct
        User storage maybeEmpty = users[name];
        return maybeEmpty.owner == 0;
    }

    function register(bytes32 name, bytes agentId) public {
        _register(User(name, agentId, msg.sender, ""));
    }

    function setSupplement(bytes32 name, bytes supplement) public onlyOwnName(name) {
        users[name].dhtSupplement = supplement;
        emit UserRegistered(name);
    }

    function transfer(bytes32 name, address newOwner) public onlyOwnName(name) {
        users[name].owner = newOwner;
        emit UserTransfered(name);
    }

    function _register(User user) internal {
        require(user.name != 0, "Name must be non-zero.");
        require(user.owner != 0, "Owner address must be non-zero.");

        require(nameIsAvailable(user.name), "Name already taken.");

        users[user.name] = user;
    }
}
