// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity 0.8.20;

interface IStealthERC721 {
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    event StealthTransfer(address indexed stealthRecipient, bytes32 publishedDataX, bytes32 publishedDataY);

    function mint(address recipient, uint256 tokenId) external;

    function register(bytes32 publicKeyX, bytes32 publicKeyY) external;

    function stealthTransfer(address stealthRecipient, uint256 tokenId, bytes32 publishedDataX, bytes32 publishedDataY)
        external;

    function getStealthAddress(address recipientAddress, uint256 secret)
        external
        returns (address stealthAddress, bytes32 publishedDataX, bytes32 publishedDataY);

    function computeStealthAccountPK(bytes32 receiverPK, bytes32 publishedDataX, bytes32 publishedDataY)
        external
        returns (bytes32);
}
