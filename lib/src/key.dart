import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/ecc/api.dart' show ECSignature, ECPoint;
import 'package:pointycastle/src/utils.dart';

import './exception.dart';
import './key_base.dart';
import './signature.dart';

/// FLON Public Key
class FLONPublicKey extends FLONKey {
  ECPoint? q;

  /// Construct FLON public key from buffer
  FLONPublicKey.fromPoint(this.q);

  /// Construct FLON public key from string
  factory FLONPublicKey.fromString(String keyStr) {
    RegExp publicRegex = RegExp(r"^PUB_([A-Za-z0-9]+)_([A-Za-z0-9]+)",
        caseSensitive: true, multiLine: false);
    Iterable<Match> match = publicRegex.allMatches(keyStr);

    if (match.isEmpty) {
      RegExp amaRegex = RegExp(r"^FU", caseSensitive: true, multiLine: false);
      if (!amaRegex.hasMatch(keyStr)) {
        throw InvalidKey("Missing prefix FU");
      }
      String publicKeyStr = keyStr.substring(2);
      Uint8List buffer = FLONKey.decodeKey(publicKeyStr);
      return FLONPublicKey.fromBuffer(buffer);
    } else if (match.length == 1) {
      Match m = match.first;
      String? keyType = m.group(1);
      Uint8List buffer = FLONKey.decodeKey(m.group(2)!, keyType);
      return FLONPublicKey.fromBuffer(buffer);
    } else {
      throw InvalidKey('Invalid public key format');
    }
  }

  factory FLONPublicKey.fromBuffer(Uint8List buffer) {
    ECPoint? point = FLONKey.secp256k1.curve.decodePoint(buffer);
    return FLONPublicKey.fromPoint(point);
  }

  Uint8List toBuffer() {
    // always compressed
    return q!.getEncoded(true);
  }

  String toString() {
    return 'FU' + FLONKey.encodeKey(this.toBuffer(), keyType);
  }
}

/// FLON Private Key
class FLONPrivateKey extends FLONKey {
  Uint8List? d;
  String? format;

  late BigInt _r;
  late BigInt _s;

  /// Constructor FLON private key from the key buffer itself
  FLONPrivateKey.fromBuffer(this.d);

  /// Construct the private key from string
  /// It can come from WIF format for PVT format
  FLONPrivateKey.fromString(String keyStr) {
    RegExp privateRegex = RegExp(r"^PVT_([A-Za-z0-9]+)_([A-Za-z0-9]+)",
        caseSensitive: true, multiLine: false);
    Iterable<Match> match = privateRegex.allMatches(keyStr);

    if (match.isEmpty) {
      format = 'WIF';
      keyType = 'K1';
      // WIF
      Uint8List keyWLeadingVersion =
          FLONKey.decodeKey(keyStr, FLONKey.SHA256X2);
      int version = keyWLeadingVersion.first;
      if (FLONKey.VERSION != version) {
        throw InvalidKey("version mismatch");
      }

      d = keyWLeadingVersion.sublist(1, keyWLeadingVersion.length);
      if (d!.lengthInBytes == 33 && d!.elementAt(32) == 1) {
        // remove compression flag
        d = d!.sublist(0, 32);
      }

      if (d!.lengthInBytes != 32) {
        throw InvalidKey('Expecting 32 bytes, got ${d!.length}');
      }
    } else if (match.length == 1) {
      format = 'PVT';
      Match m = match.first;
      keyType = m.group(1);
      d = FLONKey.decodeKey(m.group(2)!, keyType);
    } else {
      throw InvalidKey('Invalid Private Key format');
    }
  }

  /// Generate FLON private key from seed. Please note: This is not random!
  /// For the given seed, the generated key would always be the same
  factory FLONPrivateKey.fromSeed(String seed) {
    Digest s = sha256.convert(utf8.encode(seed));
    return FLONPrivateKey.fromBuffer(Uint8List.fromList(s.bytes));
  }

  /// Generate the random FLON private key
  factory FLONPrivateKey.fromRandom() {
//    final int randomLimit = 1 << 32;
    final int randomLimit = 4294967296;
    Random randomGenerator;
    try {
      randomGenerator = Random.secure();
    } catch (e) {
      randomGenerator = Random();
    }

    int randomInt1 = randomGenerator.nextInt(randomLimit);
    Uint8List entropy1 = encodeBigInt(BigInt.from(randomInt1));

    int randomInt2 = randomGenerator.nextInt(randomLimit);
    Uint8List entropy2 = encodeBigInt(BigInt.from(randomInt2));

    int randomInt3 = randomGenerator.nextInt(randomLimit);
    Uint8List entropy3 = encodeBigInt(BigInt.from(randomInt3));

    List<int> entropy = entropy1.toList();
    entropy.addAll(entropy2);
    entropy.addAll(entropy3);
    Uint8List randomKey = Uint8List.fromList(entropy);
    Digest d = sha256.convert(randomKey);
    return FLONPrivateKey.fromBuffer(Uint8List.fromList(d.bytes));
  }

  /// Check if the private key is WIF format
  bool isWIF() => this.format == 'WIF';

  /// Get the public key string from this private key
  FLONPublicKey toFLONPublicKey() {
    BigInt privateKeyNum = decodeBigIntWithSign(1, this.d!);
    ECPoint? ecPoint = FLONKey.secp256k1.G * privateKeyNum;

    return FLONPublicKey.fromPoint(ecPoint);
  }

  /// Sign the bytes data using the private key
  FLONSignature sign(Uint8List data) {
    Digest d = sha256.convert(data);
    return signHash(Uint8List.fromList(d.bytes));
  }

  /// Sign the string data using the private key
  FLONSignature signString(String data) {
    return sign(Uint8List.fromList(utf8.encode(data)));
  }

  /// Sign the SHA256 hashed data using the private key
  FLONSignature signHash(Uint8List sha256Data) {
    int nonce = 0;
    BigInt n = FLONKey.secp256k1.n;
    BigInt e = decodeBigIntWithSign(1, sha256Data);

    while (true) {
      _deterministicGenerateK(sha256Data, this.d!, e, nonce++);
      var N_OVER_TWO = n >> 1;
      if (_s.compareTo(N_OVER_TWO) > 0) {
        _s = n - _s;
      }
      ECSignature sig = ECSignature(_r, _s);

      Uint8List der = FLONSignature.ecSigToDER(sig);

      int lenR = der.elementAt(3);
      int lenS = der.elementAt(5 + lenR);
      if (lenR == 32 && lenS == 32) {
        int i = FLONSignature.calcPubKeyRecoveryParam(
            decodeBigIntWithSign(1, sha256Data), sig, this.toFLONPublicKey());
        i += 4; // compressed
        i += 27; // compact  //  24 or 27 :( forcing odd-y 2nd key candidate)
        return FLONSignature(i, sig.r, sig.s);
      }
    }
  }

  String toString() {
    List<int> version = <int>[];
    version.add(FLONKey.VERSION);
    Uint8List keyWLeadingVersion =
        FLONKey.concat(Uint8List.fromList(version), this.d!);

    return FLONKey.encodeKey(keyWLeadingVersion, FLONKey.SHA256X2);
  }

  BigInt _deterministicGenerateK(
      Uint8List hash, Uint8List x, BigInt e, int nonce) {
    List<int> newHash = hash;
    if (nonce > 0) {
      List<int> addition = Uint8List(nonce);
      List<int> data = List.from(hash)..addAll(addition);
      newHash = sha256.convert(data).bytes;
    }

    // Step B
    Uint8List v = Uint8List(32);
    for (int i = 0; i < v.lengthInBytes; i++) {
      v[i] = 1;
    }

    // Step C
    Uint8List k = Uint8List(32);

    // Step D
    List<int> d1 = List.from(v)
      ..add(0)
      ..addAll(x)
      ..addAll(newHash);

    Hmac hMacSha256 = Hmac(sha256, k); // HMAC-SHA256
    k = Uint8List.fromList(hMacSha256.convert(d1).bytes);

    // Step E
    hMacSha256 = Hmac(sha256, k); // HMAC-SHA256
    v = Uint8List.fromList(hMacSha256.convert(v).bytes);

    // Step F
    List<int> d2 = List.from(v)
      ..add(1)
      ..addAll(x)
      ..addAll(newHash);

    k = Uint8List.fromList(hMacSha256.convert(d2).bytes);

    // Step G
    hMacSha256 = Hmac(sha256, k); // HMAC-SHA256
    v = Uint8List.fromList(hMacSha256.convert(v).bytes);
    // Step H1/H2a, again, ignored as tlen === qlen (256 bit)
    // Step H2b again
    v = Uint8List.fromList(hMacSha256.convert(v).bytes);

    BigInt T = decodeBigIntWithSign(1, v);
    // Step H3, repeat until T is within the interval [1, n - 1]
    while (T.sign <= 0 ||
        T.compareTo(FLONKey.secp256k1.n) >= 0 ||
        !_checkSig(e, Uint8List.fromList(newHash), T)) {
      List<int> d3 = List.from(v)..add(0);
      k = Uint8List.fromList(hMacSha256.convert(d3).bytes);
      hMacSha256 = Hmac(sha256, k); // HMAC-SHA256
      v = Uint8List.fromList(hMacSha256.convert(v).bytes);
      // Step H1/H2a, again, ignored as tlen === qlen (256 bit)
      // Step H2b again
      v = Uint8List.fromList(hMacSha256.convert(v).bytes);

      T = decodeBigIntWithSign(1, v);
    }
    return T;
  }

  bool _checkSig(BigInt e, Uint8List hash, BigInt k) {
    BigInt n = FLONKey.secp256k1.n;
    ECPoint Q = (FLONKey.secp256k1.G * k)!;

    if (Q.isInfinity) {
      return false;
    }

    _r = Q.x!.toBigInteger()! % n;
    if (_r.sign == 0) {
      return false;
    }

    _s = k.modInverse(FLONKey.secp256k1.n) *
        (e + decodeBigIntWithSign(1, d!) * _r) %
        n;
    if (_s.sign == 0) {
      return false;
    }

    return true;
  }
}
