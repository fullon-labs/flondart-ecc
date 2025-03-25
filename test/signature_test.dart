import 'dart:convert';
import 'dart:typed_data';

import '../lib/flondart_ecc.dart';
import 'package:test/test.dart';
import 'package:crypto/crypto.dart';

void main() {
  group('FLON signature tests', () {
    test('Construct FLON signature from string', () {
      String sigStr =
          'SIG_K1_Kg417TSLuhzSpU2bGa21kD1UNaTfAZSCcKmKpZ6fnx3Nqu22gzG3ND4Twur7bzX8oS1J91JvV4rMJcFycGqFBSaY2SJcEQ';
      FLONSignature signature = FLONSignature.fromString(sigStr);
      print(signature);

      expect(sigStr, signature.toString());
    });

    test('Sign the hash using private key', () {
      FLONPrivateKey privateKey = FLONPrivateKey.fromString(
          '5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3');
      FLONPublicKey publicKey = privateKey.toFLONPublicKey();
      String expectedSig =
          'SIG_K1_Kg417TSLuhzSpU2bGa21kD1UNaTfAZSCcKmKpZ6fnx3Nqu22gzG3ND4Twur7bzX8oS1J91JvV4rMJcFycGqFBSaY2SJcEQ';

      String data = 'data';
      Uint8List hashData = sha256.convert(utf8.encode(data)).bytes as Uint8List;
      FLONSignature signature = privateKey.signHash(hashData);
      FLONSignature signature2 = privateKey.signString(data);

      print(signature.toString());
      expect(expectedSig, signature.toString());
      expect(true, signature.verifyHash(hashData, publicKey));
      expect(true, signature2.verifyHash(hashData, publicKey));

      expect(true, signature.verify(data, publicKey));
      expect(true, signature2.verify(data, publicKey));
    });

    test('Sign the hash using private key', () {
      FLONPrivateKey privateKey = FLONPrivateKey.fromString(
          '5HxT6prWB8VuXkoAaX3eby8bWjquMtCvGuakhC8tGEiPSHfsQLR');
      FLONPublicKey publicKey = privateKey.toFLONPublicKey();
      String expectedSig =
          'SIG_K1_Kdfe9wknSAKBmgwb3L53CG8KosoHhZ69oVEJrrH5YuWx4JVcJdn1ZV3MU25AVho4mPbeSKW79DVTBAAWj7zGbHTByF1JXU';

      List<int> l = [
        244,
        163,
        240,
        75,
        174,
        150,
        233,
        185,
        227,
        66,
        27,
        130,
        230,
        139,
        102,
        112,
        128,
        38,
        78,
        233,
        105,
        59,
        61,
        11,
        25,
        221,
        42,
        109,
        80,
        184,
        174,
        201
      ];
      Uint8List hashData = Uint8List.fromList(l);
      FLONSignature signature = privateKey.signHash(hashData);

      expect(expectedSig, signature.toString());
      print(signature.toString());
      expect(true, signature.verifyHash(hashData, publicKey));
    });

    test('Sign the hash using private key', () {
      FLONPrivateKey privateKey = FLONPrivateKey.fromString(
          '5J9b3xMkbvcT6gYv2EpQ8FD4ZBjgypuNKwE1jxkd7Wd1DYzhk88');
      FLONPublicKey publicKey = privateKey.toFLONPublicKey();
      String expectedSig =
          'SIG_K1_KWfDGxwogny1PUiBAYTfKwPsCSNvM7zWgmXyChdYayZFfyPjddpBUYVdJTq1PjC3PRXADRsqWVU1N2SMQivBDqA7AaRzmB';

      List<int> l = [
        136,
        139,
        63,
        11,
        114,
        68,
        227,
        116,
        92,
        61,
        64,
        121,
        147,
        210,
        233,
        25,
        74,
        164,
        140,
        112,
        45,
        5,
        254,
        165,
        208,
        158,
        53,
        212,
        128,
        190,
        153,
        142
      ];
      Uint8List hashData = Uint8List.fromList(l);
      FLONSignature signature = privateKey.signHash(hashData);

      expect(expectedSig, signature.toString());
      print(signature.toString());
      expect(true, signature.verifyHash(hashData, publicKey));
    });

    test('Recover FLONPublicKey from sign data', () {
      const data = 'this is some data to sign';

      var eosPrivateKey = FLONPrivateKey.fromRandom();
      var eosPublicKey = eosPrivateKey.toFLONPublicKey();

      var signature = eosPrivateKey.signString(data);

      var recoveredFLONPublicKey = signature.recover(data);

      expect(eosPublicKey.toString(), recoveredFLONPublicKey.toString());
      print('Generated FLONPublicKey : ${eosPublicKey.toString()}');
      print('Recovered FLONPublicKey : ${recoveredFLONPublicKey.toString()}');
    });
  });
}
