pragma solidity ^0.5.0;

// import {UserRegistry} from "./UserRegistry.sol";

contract ConsentRegistry {
    struct Consent {
        // User user;
        address owner;
        uint256 timestamp;
        bytes32 userEmail;
        uint8[] consentLevels;
    }

    // Mapping from user's email to user's consent
    mapping(bytes32 => Consent) userMailToConsent;

    function setConsent(bytes32 email, uint8[] memory consentLevels) public {
        _createConsent(Consent(msg.sender, now, email, consentLevels));
    }

    function _createConsent(Consent memory consent) private {
        userMailToConsent[consent.userEmail] = consent;
    }

    function checkConsent(bytes32 email) public view returns(uint8[] memory) {
        return userMailToConsent[email].consentLevels;
    }

    // TODO Delegated function calls to enable setting the consent from a service without forcing the node operator to pay all fees.

    // ----------------- Testing functions -------------------

    function getConsent(bytes32 email) public view returns(address, bytes32, uint8[] memory) {
        Consent memory consent = userMailToConsent[email];
        return (consent.owner, consent.userEmail, consent.consentLevels);
    }
}
