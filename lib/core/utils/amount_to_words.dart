// lib/core/utils/amount_to_words.dart
// Converts numeric amounts to Indian English word representation
// Example: 500.00 → "Five Hundred Rupees Only"

class AmountToWords {
  AmountToWords._();

  static const List<String> _ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  /// Converts a double amount to Indian English words.
  /// e.g. 500 → "Five Hundred Rupees Only"
  /// e.g. 1 → "One Rupee Only"
  /// e.g. 1500.50 → "One Thousand Five Hundred Rupees And Fifty Paise Only"
  static String convert(double amount, {bool uppercase = false}) {
    if (amount < 0) {
      return uppercase ? 'INVALID AMOUNT' : 'Invalid Amount';
    }
    if (amount == 0) {
      return uppercase ? 'ZERO RUPEES ONLY' : 'Zero Rupees Only';
    }

    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();

    final StringBuffer buffer = StringBuffer();

    if (rupees > 0) {
      buffer.write(_numberToWords(rupees));
      buffer.write(rupees == 1 ? ' Rupee' : ' Rupees');
    }

    if (paise > 0) {
      if (rupees > 0) buffer.write(' And ');
      buffer.write(_numberToWords(paise));
      buffer.write(' Paise');
    }

    buffer.write(' Only');

    final result = buffer.toString().trim();
    return uppercase ? result.toUpperCase() : result;
  }

  /// Internal: converts an integer to Indian number system words.
  static String _numberToWords(int n) {
    if (n <= 0) return '';

    final StringBuffer buffer = StringBuffer();

    // Crores (10,000,000)
    if (n >= 10000000) {
      buffer.write('${_numberToWords(n ~/ 10000000)} Crore');
      n = n % 10000000;
      if (n > 0) buffer.write(' ');
    }

    // Lakhs (100,000)
    if (n >= 100000) {
      buffer.write('${_numberToWords(n ~/ 100000)} Lakh');
      n = n % 100000;
      if (n > 0) buffer.write(' ');
    }

    // Thousands (1,000)
    if (n >= 1000) {
      buffer.write('${_numberToWords(n ~/ 1000)} Thousand');
      n = n % 1000;
      if (n > 0) buffer.write(' ');
    }

    // Hundreds
    if (n >= 100) {
      buffer.write('${_ones[n ~/ 100]} Hundred');
      n = n % 100;
      if (n > 0) buffer.write(' ');
    }

    // Tens and Ones
    if (n >= 20) {
      buffer.write(_tens[n ~/ 10]);
      final int rem = n % 10;
      if (rem > 0) {
        buffer.write(' ');
        buffer.write(_ones[rem]);
      }
    } else if (n > 0) {
      buffer.write(_ones[n]);
    }

    return buffer.toString().trim();
  }
}
