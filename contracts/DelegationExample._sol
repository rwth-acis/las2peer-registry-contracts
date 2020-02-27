pragma solidity ^0.5.0;

import { Delegation } from "./Delegation.sol";


/**
 * Demonstrates how Delegation can be used.
 * This contract is not required in production, but is used for testing.
 *
 * This pattern is probably for from perfect, feel free to improve.
 */
contract DelegationExample {
    /**
     * Some function to be invoked directly, merely calls the private implementation
     */
    function testFunction(uint256 a, string memory b) public view returns(uint256) {
        return _testFunction(a, b, msg.sender);
    }

    /**
     * This function can be called by anyone but requires a signature.
     * Its effect should be indentical to that of the consentee calling
     * testFunction(a, b) directly.
     * But rather than the permission check there, we perform the equivalent here.
     */
    function delegatedTestFunction(
        uint256 a,
        string memory b,
        address consentee,
        bytes memory consentSignature
    )
    public
    pure
    returns(uint256)
    {
        // 8 chars of keccak256("testFunction(uint256,string)")
        // note: type aliases (e.g., uint) are replaced by their actual types (uint256)
        // note: storage/memory are not considered
        bytes memory methodId = hex"37dab627";

        // regardless of whether the args are fixed or dynamic length, just encode them like this:
        bytes memory args = abi.encode(a, b);

        // this will revert if:
        // * signature is not a valid signature, or
        // * signature does not belong to the content (which is the encoded function call, computed from methodId and args)
        // * signature was not created by consentee
        Delegation.checkConsent(methodId, args, consentee, consentSignature);

        return _testFunction(a, b, consentee);
    }

    function _testFunction(uint a, string memory b, address subject) private pure returns(uint256) {
        require(subject != address(0), "[This is an example check]"); // do actual permissions check here
        return 42;
    }
}
