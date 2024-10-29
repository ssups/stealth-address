// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IStealthERC721} from "./interfaces/IStealthERC721.sol";
import {Secp256k1} from "./libraries/Secp256k1.sol";

contract StealthERC721 is IStealthERC721, ERC721 {
    mapping(address user => PublicKey) public publicKeyOf;

    constructor() ERC721("Stealth NFT", "ST") {}

    function mint(address recipient, uint256 tokenId) external {
        _mint(recipient, tokenId);
    }

    function register(bytes32 publicKeyX, bytes32 publicKeyY) external {
        address calcedAddress = address(bytes20(keccak256(abi.encode(publicKeyX, publicKeyY)) << 96));
        require(msg.sender == calcedAddress, "Pub key does not belong to sender");
        publicKeyOf[msg.sender] = PublicKey({x: publicKeyX, y: publicKeyY});
    }

    function stealthTransfer(address stealthRecipient, uint256 tokenId, bytes32 publishedDataX, bytes32 publishedDataY)
        external
    {
        transferFrom(msg.sender, stealthRecipient, tokenId);
        emit StealthTransfer(stealthRecipient, publishedDataX, publishedDataY);
    }

    function getStealthAddress(address recipientAddress, uint256 secret)
        external
        view
        returns (address stealthAddress, bytes32 publishedDataX, bytes32 publishedDataY)
    {
        PublicKey storage pubKey = publicKeyOf[recipientAddress];

        require(pubKey.x != bytes32(0) && pubKey.y != bytes32(0), "Receipent not registered yet");

        (uint256 publishedX, uint256 publishedY) = Secp256k1.mulWithG(secret);
        (uint256 sharedSecretX, uint256 sharedSecretY) = Secp256k1.mul(secret, uint256(pubKey.x), uint256(pubKey.y));
        bytes32 sharedSecretHash = keccak256(abi.encode(sharedSecretX, sharedSecretY));
        (uint256 x, uint256 y) = Secp256k1.mulWithG(uint256(sharedSecretHash));
        (uint256 stealthPubX, uint256 stealthPubY) = Secp256k1.add(x, y, uint256(pubKey.x), uint256(pubKey.y));
        stealthAddress = address(bytes20(keccak256(abi.encode(stealthPubX, stealthPubY)) << 96));
        return (stealthAddress, bytes32(publishedX), bytes32(publishedY));
    }

    function computeStealthAccountPK(bytes32 receiverPK, bytes32 publishedDataX, bytes32 publishedDataY)
        external
        pure
        returns (bytes32)
    {
        (uint256 sharedSecretX, uint256 sharedSecretY) =
            Secp256k1.mul(uint256(receiverPK), uint256(publishedDataX), uint256(publishedDataY));
        bytes32 sharedSecretHash2 = keccak256(abi.encode(sharedSecretX, sharedSecretY));

        // (pk + sharedSecret) % (PK_MAX + 1)
        uint256 stealthAccountPK = addmod(uint256(receiverPK), uint256(sharedSecretHash2), Secp256k1.PK_MAK + 1);
        return bytes32(stealthAccountPK);
    }
}
