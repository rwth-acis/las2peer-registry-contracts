pragma solidity ^0.5.0;

contract ConsentRegistry {

    // TODO declare events

    // TODO Clearify: Data structure, user identification
    struct Consent {
        // TODO: Check referencing a User based on struct in userRegistry
        address owner;
        bytes32 userName;

        // Data access operation => true (consent given)/false (no consent)
        // Refer to data access operations?
        // e.g. LMS-Retrieval => true, Personalized-LA-feedback => false
        mapping(bytes32 => bool) consentByOperation;

        // Alternative: Hash referencing the stored consent data.
        // byte32 dataPointer;
    }

    mapping(address => Consent[]) userToConsent;

    function ConsentRegistry(){

    }

    // params: userID?, Consentdata
    function setConsent() public returns(bool) {
        // TODO
        return true;
    }

    // params: userID, Consentdata
    // Necessary?
    function updateConsent() public returns(bool) {
        // TODO
        return true;
    }

    // params: userID, access operation
    function checkConsent() public view returns(bool) {
        // TODO
        return true;
    }


}
