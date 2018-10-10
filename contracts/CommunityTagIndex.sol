pragma solidity ^0.4.24;


/**
 * Community tag index
 *
 * Allows the creation of a tag, consisting of a 32-byte name and a
 * string description. Creation is free.
 */
contract CommunityTagIndex {
    event CommunityTagCreated(bytes32 name);

    struct CommunityTag {
        bytes32 name;
        string description;
    }

    mapping (bytes32 => CommunityTag) public tagIndex;

    function isAvailable(bytes32 name) public view returns(bool) {
        CommunityTag storage maybeEmpty = tagIndex[name];
        return maybeEmpty.name == 0;
    }

    function create(bytes32 name, string description) public {
        require(name != 0, "Tag name must be non-zero.");
        //require(keccak256(description) != keccak256(""), "Description must be non-empty");
        // not sure if this encodePacked is necessary, but it silences the warning:
        require(keccak256(abi.encodePacked(description)) != keccak256(""), "Description must be non-empty");
        require(isAvailable(name), "A tag with this name already exists.");

        tagIndex[name] = CommunityTag(name, description);
        emit CommunityTagCreated(name);
    }

    function viewDescription(bytes32 name) public view returns(string) {
        //require(!isAvailable(name)); // not needed
        return tagIndex[name].description;
    }
}
