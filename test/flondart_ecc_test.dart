import '../lib/flondart_ecc.dart';
import 'package:test/test.dart';

void main() {
  group('FLON Key tests', () {
    test('Construct FLON public key from string', () {
      FLONPublicKey publicKey = FLONPublicKey.fromString(
          'FU8Qi58kbERkTJC7A4gabxYU4SbrAxStJHacoke4sf6AvJyEDZXj');
      print(publicKey);

      expect('FU8Qi58kbERkTJC7A4gabxYU4SbrAxStJHacoke4sf6AvJyEDZXj',
          publicKey.toString());
    });

    test('Construct FLON public key from string PUB_K1 format', () {
      FLONPublicKey publicKey = FLONPublicKey.fromString(
          'PUB_K1_859gxfnXyUriMgUeThh1fWv3oqcpLFyHa3TfFYC4PK2Ht7beeX');
      print(publicKey);
    });

    test('Construct FLON private key from string', () {
      // common private key
      FLONPrivateKey privateKey = FLONPrivateKey.fromString(
          '5J9b3xMkbvcT6gYv2EpQ8FD4ZBjgypuNKwE1jxkd7Wd1DYzhk88');
      expect('FU8Qi58kbERkTJC7A4gabxYU4SbrAxStJHacoke4sf6AvJyEDZXj',
          privateKey.toFLONPublicKey().toString());
      expect('5J9b3xMkbvcT6gYv2EpQ8FD4ZBjgypuNKwE1jxkd7Wd1DYzhk88',
          privateKey.toString());
    });

    test('Invalid FLON private key', () {
      try {
        FLONPrivateKey.fromString(
            '5KYZdUEo39z3FPrtuX2QbbwGnNP5zTd7yyr2SC1j299sBCnWjsm');
        fail('Should be invalid private key');
      } on InvalidKey {
      } catch (e) {
        fail('Should throw InvalidKey exception');
      }
    });

    test('Construct random FLON private key from seed', () {
      FLONPrivateKey privateKey = FLONPrivateKey.fromSeed('abc');
      print(privateKey);
      print(privateKey.toFLONPublicKey());

      FLONPrivateKey privateKey2 =
          FLONPrivateKey.fromString(privateKey.toString());
      expect(privateKey.toFLONPublicKey().toString(),
          privateKey2.toFLONPublicKey().toString());
    });

    test('Construct random FLON private key', () {
      FLONPrivateKey privateKey = FLONPrivateKey.fromRandom();

      print(privateKey);
      print(privateKey.toFLONPublicKey());

      FLONPrivateKey privateKey2 =
          FLONPrivateKey.fromString(privateKey.toString());
      expect(privateKey.toFLONPublicKey().toString(),
          privateKey2.toFLONPublicKey().toString());
    });

    test('Construct FLON private key from string in PVT format', () {
      // PVT private key
      FLONPrivateKey privateKey2 = FLONPrivateKey.fromString(
          'PVT_K1_2jH3nnhxhR3zPUcsKaWWZC9ZmZAnKm3GAnFD1xynGJE1Znuvjd');
      print(privateKey2);
    });

    test('Construct FLON private key from string with compress flag', () {
      // Compressed private key
      FLONPrivateKey privateKey3 = FLONPrivateKey.fromString(
          'L5TCkLizyYqjvKSy6jg1XM3Lc4uTDwwvHS2BYatyXSyoS8T5kC2z');
      print(privateKey3);
    });
  });
}
