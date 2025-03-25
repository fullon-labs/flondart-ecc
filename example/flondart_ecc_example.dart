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

  // Recover the FLONPublicKey used to sign the data
  var recoveredFLONPublicKey = signature.recover(data);
  print(recoveredFLONPublicKey.toString());

  // Verify the data using the signature
  signature.verify(data, publicKey);
}
