// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EllipticCurve.sol";

/**
 * @title Secp256k1 Elliptic Curve
 * @notice Example of particularization of Elliptic Curve for secp256k1 curve
 * @author Witnet Foundation
 */
library Secp256k1 {
    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 public constant PK_MAK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140;

    /// @notice Public Key derivation from private key
    /// Warning: this is just an example. Do not expose your private key.
    /// @param privKey The private key
    /// @return (qx, qy) The Public Key
    function derivePubKey(uint256 privKey) internal pure returns (uint256, uint256) {
        return EllipticCurve.ecMul(privKey, GX, GY, AA, PP);
    }

    /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
    /// @param scalar scalar to multiply
    /// @param x coordinate x of P1
    /// @param y coordinate y of P1
    function mul(uint256 scalar, uint256 x, uint256 y) internal pure returns (uint256, uint256) {
        return EllipticCurve.ecMul(scalar, x, y, AA, PP);
    }

    function mulWithG(uint256 scalar) internal pure returns (uint256, uint256) {
        return mul(scalar, GX, GY);
    }

    function add(uint256 x1, uint256 y1, uint256 x2, uint256 y2) internal pure returns (uint256, uint256) {
        return EllipticCurve.ecAdd(x1, y1, x2, y2, AA, PP);
    }

    function isOnCurve(uint256 x, uint256 y) internal pure returns (bool) {
        return EllipticCurve.isOnCurve(x, y, AA, BB, PP);
    }
}
