import 'package:flutter/services.dart';

/// Converts Persian and Arabic digits before digits-only filtering runs.
class LocalizedDigitsFormatter extends TextInputFormatter {
  const LocalizedDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAllMapped(RegExp('[۰-۹٠-٩]'), (match) {
      final digit = match[0]!.codeUnitAt(0);
      return String.fromCharCode(
        0x30 + digit - (digit >= 0x06f0 ? 0x06f0 : 0x0660),
      );
    });
    return newValue.copyWith(text: text);
  }
}
