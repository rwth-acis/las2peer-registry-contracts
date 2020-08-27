pragma solidity ^0.5.0;

contract ConsentRegistry {

    // TODO Just a draft until better solution is found.
    enum ConsentLevel {
        None,
        Extraction,
        Analysis,
        All
    }

    // TODO Clearify: Data structure, user identification
    struct Consent {
        address owner;
        bytes32 userEmail;
        ConsentLevel consentLevel;
    }

    // Mapping from user's email to user's consent
    mapping(byte32 => Consent[]) userMailToConsent;

    function setConsent(bytes32 email, uint consentLevel) public {
        _createConsent(Consent(msg.sender, email, ConsentLevel(consentLevel)));
    }

    function _createConsent(Consent memory consent) private {
        userMailToConsent[consent.userEmail] = consent;
    }

    function checkConsent(bytes32 email) public view returns(uint) {
        return uint(userMailToConsent[email].consentLevel);
    }

    // TODO Delegated function calls to enable setting the consent from a service without forcing the node operator to pay all fees.

    // ----------------- Testing functions -------------------

    function getConsent(bytes32 email) public returns(address, bytes32, uint) {
        Consent consent = userMailToConsent[email];
        return (consent.owner, consent.userEmail, uint(consent.consentLevel));
    }
}
