import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import "package:pointycastle/api.dart" show PublicKeyParameter;
import "package:pointycastle/digests/sha256.dart";
import 'package:pointycastle/ecc/api.dart' show ECPublicKey, ECSignature, ECPoint;
import 'package:pointycastle/macs/hmac.dart';
import "package:pointycastle/signers/ecdsa_signer.dart";
import 'package:pointycastle/src/utils.dart';

import './exception.dart';
import './key.dart';
import './key_base.dart';

/// FLON Signature
class FLONSignature extends FLONKey {
  int? i;
  late ECSignature ecSig;

  /// Default constructor from i, r, s
  FLONSignature(this.i, BigInt r, BigInt s) {
    this.keyType = 'K1';
    this.ecSig = ECSignature(r, s);
  }

  /// Construct FLON signature from buffer
  FLONSignature.fromBuffer(Uint8List buffer, String? keyType) {
    this.keyType = keyType;

    if (buffer.lengthInBytes != 65) {
      throw InvalidKey('Invalid signature length, got: ${buffer.lengthInBytes}');
    }

    i = buffer.first;

    if (i! - 27 != i! - 27 & 7) {
      throw InvalidKey('Invalid signature parameter');
    }

    BigInt r = decodeBigIntWithSign(1, buffer.sublist(1, 33));
    BigInt s = decodeBigIntWithSign(1, buffer.sublist(33, 65));
    this.ecSig = ECSignature(r, s);
  }

  /// Construct FLON signature from string
  factory FLONSignature.fromString(String signatureStr) {
    RegExp sigRegex = RegExp(r"^SIG_([A-Za-z0-9]+)_([A-Za-z0-9]+)", caseSensitive: true, multiLine: false);
    Iterable<Match> match = sigRegex.allMatches(signatureStr);

    if (match.length == 1) {
      Match m = match.first;
      String? keyType = m.group(1);
      Uint8List key = FLONKey.decodeKey(m.group(2)!, keyType);
      return FLONSignature.fromBuffer(key, keyType);
    }

    throw InvalidKey("Invalid FLON signature");
  }

  /// Verify the signature of the string data
  bool verify(String data, FLONPublicKey publicKey) {
    Digest d = sha256.convert(utf8.encode(data));

    return verifyHash(Uint8List.fromList(d.bytes), publicKey);
  }

  /// Verify the signature from in SHA256 hashed data
  bool verifyHash(Uint8List sha256Data, FLONPublicKey publicKey) {
    ECPoint? q = publicKey.q;
    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    signer.init(false, PublicKeyParameter(ECPublicKey(q, FLONKey.secp256k1)));

    return signer.verifySignature(sha256Data, this.ecSig);
  }

  /**
    * Recover the public key used to create this signature using full data.
    * @arg {String|Uint8List|List<int>} data - full data
    * @return {FLONPublicKey}
    */
  FLONPublicKey recover(dynamic data) {
    var digest;

    if (data is String) {
      var dataBuf = Uint8List.fromList(data.codeUnits);
      digest = sha256.convert(dataBuf);
    } else if (data is Uint8List || data is List<int>) {
      digest = sha256.convert(data);
    } else {
      throw 'data must be String or uint8list';
    }

    return recoverHash(digest);
  }

  /**
    *  @arg {Digest} dataSha256 - sha256 hash 32 byte buffer
    *  @return {FLONPublicKey}
    */
  FLONPublicKey recoverHash(Digest dataSha256) {
    var dataSha256Buf = dataSha256.bytes;
    if (dataSha256Buf.length != 32) {
      throw "dataSha256: 32 byte String or buffer required";
    }

    var e = decodeBigIntWithSign(1, dataSha256Buf);
    var i2 = i!;
    i2 -= 27;
    i2 = i2 & 3;

    var q = recoverPubKey(e, ecSig, i2);

    return FLONPublicKey.fromPoint(q);
  }

  String toString() {
    List<int> b = <int>[];
    b.add(i!);
    b.addAll(encodeBigInt(this.ecSig.r));
    b.addAll(encodeBigInt(this.ecSig.s));

    Uint8List buffer = Uint8List.fromList(b);
    return 'SIG_${keyType}_${FLONKey.encodeKey(buffer, keyType)}';
  }

  /// ECSignature to DER format bytes
  static Uint8List ecSigToDER(ECSignature ecSig) {
    List<int> r = FLONKey.toSigned(encodeBigInt(ecSig.r));
    List<int> s = FLONKey.toSigned(encodeBigInt(ecSig.s));

    List<int> b = <int>[];
    b.add(0x02);
    b.add(r.length);
    b.addAll(r);

    b.add(0x02);
    b.add(s.length);
    b.addAll(s);

    b.insert(0, b.length);
    b.insert(0, 0x30);

    return Uint8List.fromList(b);
  }

  /// Find the public key recovery factor
  static int calcPubKeyRecoveryParam(BigInt e, ECSignature ecSig, FLONPublicKey publicKey) {
    for (int i = 0; i < 4; i++) {
      ECPoint? Qprime = recoverPubKey(e, ecSig, i);
      if (Qprime == publicKey.q) {
        return i;
      }
    }
    throw 'Unable to find valid recovery factor';
  }

  /// Recovery FLON public key from ECSignature
  static ECPoint? recoverPubKey(BigInt e, ECSignature ecSig, int i) {
    BigInt n = FLONKey.secp256k1.n;
    ECPoint G = FLONKey.secp256k1.G;

    BigInt r = ecSig.r;
    BigInt s = ecSig.s;

    // A set LSB signifies that the y-coordinate is odd
    int isYOdd = i & 1;

    // The more significant bit specifies whether we should use the
    // first or second candidate key.
    int isSecondKey = i >> 1;

    // 1.1 Let x = r + jn
    BigInt x = isSecondKey > 0 ? r + n : r;
    ECPoint R = FLONKey.secp256k1.curve.decompressPoint(isYOdd, x);
    ECPoint nR = (R * n)!;
    if (!nR.isInfinity) {
      throw 'nR is not a valid curve point';
    }

    BigInt eNeg = (-e) % n;
    BigInt rInv = r.modInverse(n);

    ECPoint? Q = multiplyTwo(R, s, G, eNeg)! * rInv;
    return Q;
  }

  static bool testBit(BigInt j, int n) {
    return (j >> n).toUnsigned(1).toInt() == 1;
  }

  static ECPoint? multiplyTwo(ECPoint t, BigInt j, ECPoint x, BigInt k) {
    int i = max(j.bitLength, k.bitLength) - 1;
    ECPoint? R = t.curve.infinity;
    ECPoint? both = t + x;

    while (i >= 0) {
      bool jBit = testBit(j, i);
      bool kBit = testBit(k, i);

      R = R!.twice();

      if (jBit) {
        if (kBit) {
          R = R! + both;
        } else {
          R = R! + t;
        }
      } else if (kBit) {
        R = R! + x;
      }

      --i;
    }

    return R;
  }
}
