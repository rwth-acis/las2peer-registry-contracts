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
        address signer,
        bytes memory signature
    )
        public
        pure
    {
        // let's be very explicit here. this may seem over-elaborate, but since I've messed this up repeatedly,
        // let's take things slow

        // the actual content of our message is the encoded call
        bytes memory data = _encodeCall(methodId, args);
        // but to make things easier, we just use the hash
        bytes32 dataHash = keccak256(data);

        // now we do what eth_sign does:
        // put that in an Ethereum-specific envelope
        bytes memory envelope = _putDataInEnvelope(dataHash);
        // and hash it
        bytes32 envelopeHash = keccak256(envelope);
        // this hash is the actual thing that's cryptographically signed
        // (on a low level; this is not exposed in the API)

        // so this is what we check: does the signature match the encoded call data,
        // and was it signed by the claimed signer?
        _checkSignature(envelopeHash, signer, signature);
    }

    /**
     * Checks whether signature is valid for message and returns signer
     */
    function _checkSignature(
        bytes32 hashOfMessage,
        address signer,
        bytes memory signature
    )
        internal
        pure
    {
        address actualSigner = ECDSA.recover(hashOfMessage, signature);
        require(keccak256(abi.encodePacked(actualSigner)) != keccak256(abi.encodePacked(address(0))), "Signature not valid.");
        require(keccak256(abi.encodePacked(actualSigner)) == keccak256(abi.encodePacked(signer)), "Signature does not match claimed signer.");
    }

    /**
     * Compute encoded function call as bytes, compatible with
     * https://web3js.readthedocs.io/en/1.0/web3-eth-abi.html#encodefunctioncall
     */
    function _encodeCall(bytes memory methodId, bytes memory args) internal pure returns(bytes memory) {
        return abi.encodePacked(methodId, args);
    }

    /**
     * Envelope data as Ethereum signed message, as used in
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign
     *
     * Careful: Some implementations of `sign` automatically hash the data before putting it in the envelope,
     * others do not. Check what is happening in whatever library you use.
     * In our signed consent messages, the data is hashed.
     * In order to be unambiguous, we take the hash as argument here.
     *
     * web3.js does not automatically hash the message data, so be sure to use something like:
     *     web3.eth.accounts.sign(web3.utils.sha3(data), privateKey).signature
     * https://web3js.readthedocs.io/en/1.0/web3-eth-accounts.html#sign
     */
    function _putDataInEnvelope(bytes32 hashOfData) internal pure returns(bytes memory) {
        // the 32 indicates the length (always 32 because we use the hash)
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        // yes, encodePacked not encode
        bytes memory envelope = abi.encodePacked(prefix, hashOfData);

        return envelope;
    }
}
