const PrivacyConsentRegistry = artifacts.require('PrivacyConsentRegistry')
const DataProcessingPurposes = artifacts.require('DataProcessingPurposes')
const XAPIVerificationRegistry = artifacts.require('xAPIVerificationRegistry')

module.exports = function (deployer) {
    deployer.deploy(PrivacyConsentRegistry)
    deployer.deploy(DataProcessingPurposes)
    deployer.deploy(XAPIVerificationRegistry)
};
