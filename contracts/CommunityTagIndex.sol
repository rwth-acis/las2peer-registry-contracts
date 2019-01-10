pragma solidity ^0.4.24;

import { ECDSA } from "./ECDSA.sol";


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

    // DEBUG
    function add(uint a, uint b) public pure returns(uint) {
        return a + b;
    }

    // this works with Web3J-generated signature like this:
    // https://gist.github.com/tjanson/635abe67798d2d8cd8d24d31d912fab4
    function delegatedAdd(uint a, uint b, bytes signature) public pure returns(uint) {
        // first 8 chars of keccak("add(uint256,uint256)")
        bytes memory methodId = hex"771602f7";
        bytes memory args = abi.encode(a, b);

        address agent = _checkSignature(methodId, args, signature);
        return add(a, b);
    }

    function _hashCall(bytes methodId, bytes args) internal pure returns(bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 dataHash = keccak256(methodId, args);
        return keccak256(prefix, dataHash);
    }

    function _checkSignature(bytes methodId, bytes args, bytes signature) internal pure returns(address) {
        bytes32 hash = _hashCall(methodId, args);
        address signer = ECDSA.recover(hash, signature);
        require(keccak256(signer) != keccak256(0));
        return signer;
    }

    // this works (call succeeds) (e.g., try with Remix IDE)
    function demoSig() public pure {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        // first 8 chars of keccak("add(uint,uint)") -- which is wrong, but whatever
        bytes memory functionId = hex"b8966352";

        // example
        uint a = 1;
        uint b = 2;

        bytes memory args = abi.encode(a, b);
        require(keccak256(args) == keccak256(hex"00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002"));
        bytes32 dataHash = keccak256(functionId, args);
        require(dataHash == 0x2651acda880913a5dd6150267851369b1e0533bc393c70ab26d48b8016fadd4a);
        bytes32 hash = keccak256(prefix, dataHash);
        require(hash == 0xd38a8b7c0df8719069407c3c0aefbd7b5d432657279393e4d13fb615456f5877);

        // from web3j:
        // r A6E89AA2D8AEDF4E8C77FD097D80F716D6847C2B71E35B0FAB95579AF8DAB09C
        // s 5A5D4395AC1F82697A43AC4275FFBD1997BE041A546A6A9C9C2AAF7F49E9986A
        // v 1C
        bytes memory signature = hex"a6e89aa2d8aedf4e8c77fd097d80f716d6847c2b71e35b0fab95579af8dab09c5a5d4395ac1f82697a43ac4275ffbd1997be041a546a6a9c9c2aaf7f49e9986a1c";
        address signer = ECDSA.recover(hash, signature);

        require(signer == 0xee5E18b0963126CDE89dD2B826f0ACdb7E71AcDb);
    }
}
