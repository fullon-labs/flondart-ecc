# Elliptic curve cryptography (ECC) in Dart

Elliptic curve cryptography lib for FullOn blockchain in Dart lang.

## Usage

A simple usage example:

```dart
import 'package:flondart_ecc/flondart_ecc.dart';

main() {
  // Construct the FLON private key from string
  FLONPrivateKey privateKey = FLONPrivateKey.fromString(
      '5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3');

  // Get the related FLON public key
  FLONPublicKey publicKey = privateKey.toFLONPublicKey();
  // Print the FLON public key
  print(publicKey.toString());

  // Going to sign the data
  String data = 'data';

  // Sign
  FLONSignature signature = privateKey.signString(data);
  // Print the FLON signature
  print(signature.toString());

  // Verify the data using the signature
  signature.verify(data, publicKey);
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

## References

eosjs-ecc: https://github.com/EOSIO/eosjs-ecc

[tracker]: https://github.com/fullon-labs/flondart-ecc/issues
