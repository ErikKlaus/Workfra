import 'dart:convert';
void main() {
  final bytes = [0xFF, 0xD8, 0xFF, 0xE0]; // JPEG magic number
  final b64 = base64Encode(bytes);
  print(b64);
}
