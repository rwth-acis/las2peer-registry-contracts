pragma solidity ^0.5.0;

import { ECDSA } from "./ECDSA.sol";


/**
 * Cryptographic functions for method call delegation
 *
 * NOTE: This is a proof of concept. This code is not audited. Do not assume
 * that it is bug-free or free of fundamental flaws.
 *
 * The basic idea is to allow a user to sign a declaration of intent,
 * expressing consent for someone else to perform specific operations.
 * A compatible contract accepts this signature and allows the execution
 * of those operations.
 * (E.g., methods that would usually require a resource to be owned by
 * `msg.sender` instead accept the resource owner's signature.)
 *
 * We call the person signing the declaration of intent the "signer", while
 * the person invoking a smart contract method and presenting the signature is
 * called the "sender".
 *
 * This allows the signer to indirectly interact with the blockchain.
 * One particular advantage is that the sender pays the transaction fees,
 * meaning that the signer does not need to hold any ether.
 * This is why BitClave calls a similar modifier "feeless" [1], which inspired
 * this code (but is more capable and general).
 *
 * The concept is also discussed in EIP1035 [2], EIP1077 [3].
 *
 * Rather than attempting a general solution, this library provides functions
 * sufficient for the limited scope of our project.
 *
 * [1]: https://github.com/bitclave/Feeless
 * [2]: https://github.com/ethereum/EIPs/issues/1035
 * [3]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1077.md
 */
library Delegation {
    /**
     * Returns address of signer if signer consents to the call.
     * Otherwise throws state-reverting exception (failed `require`).
     *
     * The signature is interpreted as consent for the method to be called
     * as if the signer signed and sent the transaction themself (i.e.,
     * `msg.sender` is the signer's address), with the given arguments.
     *
     * The call can be triggered at any time, possibly repeatedly (!), by
     * any sender.
     *
     * @param methodId method ID a.k.a. function selector [1]
     * @param args (non-packed) encoded function arguments
     * @param signature eth_sign compatible signature of (non-packed) method ID and arguments
     *
     * [1]: https://solidity.readthedocs.io/en/develop/abi-spec.html#function-selector
     */
    function checkConsent(
        bytes memory methodId,
        bytes memory args,
        bytes memory signature
    )
        internal
        pure
        returns(address)
    {
        bytes32 hash = _hashCall(methodId, args);
        return _checkSignature(hash, signature);
    }

    /**
     * Checks whether signature is valid for message and returns signer
     */
    function _checkSignature(bytes32 hashOfMessage, bytes memory signature) internal pure returns(address) {
        address signer = ECDSA.recover(hashOfMessage, signature);
        require(keccak256(abi.encodePacked(signer)) != keccak256(abi.encodePacked(address(0))), "Signature not valid.");
        return signer;
    }

    function _hashCall(bytes memory methodId, bytes memory args) internal pure returns(bytes32) {
        return _hashForSignature(keccak256(abi.encode(methodId, args)));
    }

    /**
     * Compute hash with Ethereum-specific prefix, compatible with eth_sign
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign
     */
    function _hashForSignature(bytes32 contentHash) internal pure returns(bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encode(prefix, contentHash));
    }
}
