pragma solidity ^0.5.0;

// import {UserRegistry} from "./UserRegistry.sol";

contract ConsentRegistry {
    struct Consent {
        // User user;
        address owner;
        uint256 timestamp;
        bytes32 userId;
        uint8[] consentLevels;
    }

    // Mapping from user's ID to user's consent
    mapping(bytes32 => Consent) userConsent;

    function setConsent(bytes32 userId, uint8[] memory consentLevels) public {
        _createConsent(Consent(msg.sender, now, userId, consentLevels));
    }

    function _createConsent(Consent memory consent) private {
        userConsent[consent.userId] = consent;
    }

    function checkConsent(bytes32 userId) public view returns(uint8[] memory) {
        return userConsent[userId].consentLevels;
    }

    // TODO Delegated function calls to enable setting the consent from a service without forcing the node operator to pay all fees.

    // ----------------- Testing functions -------------------

    function getConsent(bytes32 userId) public view returns(address, bytes32, uint8[] memory) {
        Consent memory consent = userConsent[userId];
        return (consent.owner, consent.userId, consent.consentLevels);
    }
}
