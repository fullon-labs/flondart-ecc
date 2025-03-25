import '../lib/flondart_ecc.dart';
import 'package:test/test.dart';

FLONPrivateKey privateKey = FLONPrivateKey.fromString(
    '5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3');
FLONPublicKey publicKey = privateKey.toFLONPublicKey();

bool eccSignAndVerify(String data) {
  privateKey.signString(data).toString();
  FLONSignature signature = privateKey.signString(data);
  return signature.verify(data, publicKey);
}

void main() {
  group('FLON signature string tests', () {
    test('ECC Sign #1', () {
      var result = eccSignAndVerify('data');
      expect(result, true);
    });

    test('ECC Sign #2', () {
      var result = eccSignAndVerify(
          '02dd11a0cd4ec12119e2e72d1a553e657323435e08063ac511d8b7f52802cf9c');
      // Error: Value x must be smaller than q
      expect(result, true);
    });

    test('ECC Sign #3', () {
      var result = eccSignAndVerify('475');
      // Error: Value x must be smaller than q
      expect(result, true);
    });

    test('ECC Sign #4', () {
      var result = eccSignAndVerify('5488');
      // Error: Invalid point compression
      expect(result, true);
    });

    test('ECC Sign #5', () {
      var result = eccSignAndVerify('2097');
      // Error: nR is not a valid curve point
      expect(result, true);
    });
  });
}
