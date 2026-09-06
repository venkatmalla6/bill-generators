// test/core/utils/amount_to_words_test.dart
// Unit tests for AmountToWords utility

import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printer/core/utils/amount_to_words.dart';

void main() {
  group('AmountToWords', () {
    // ─── Basic Numbers ────────────────────────────────────────────────────

    test('converts zero', () {
      expect(AmountToWords.convert(0), equals('Zero Rupees Only'));
    });

    test('converts single digits', () {
      expect(AmountToWords.convert(1), equals('One Rupee Only'));
      expect(AmountToWords.convert(5), equals('Five Rupees Only'));
      expect(AmountToWords.convert(9), equals('Nine Rupees Only'));
    });

    test('converts teens', () {
      expect(AmountToWords.convert(11), equals('Eleven Rupees Only'));
      expect(AmountToWords.convert(15), equals('Fifteen Rupees Only'));
      expect(AmountToWords.convert(19), equals('Nineteen Rupees Only'));
    });

    test('converts tens', () {
      expect(AmountToWords.convert(10), equals('Ten Rupees Only'));
      expect(AmountToWords.convert(20), equals('Twenty Rupees Only'));
      expect(AmountToWords.convert(50), equals('Fifty Rupees Only'));
      expect(AmountToWords.convert(99), equals('Ninety Nine Rupees Only'));
    });

    test('converts hundreds', () {
      expect(AmountToWords.convert(100), equals('One Hundred Rupees Only'));
      expect(AmountToWords.convert(500), equals('Five Hundred Rupees Only'));
      expect(
          AmountToWords.convert(250), equals('Two Hundred Fifty Rupees Only'));
      expect(AmountToWords.convert(999),
          equals('Nine Hundred Ninety Nine Rupees Only'));
    });

    // ─── Indian Numbering System ──────────────────────────────────────────

    test('converts thousands (Indian system)', () {
      expect(AmountToWords.convert(1000), equals('One Thousand Rupees Only'));
      expect(AmountToWords.convert(5500),
          equals('Five Thousand Five Hundred Rupees Only'));
      expect(AmountToWords.convert(10000),
          equals('Ten Thousand Rupees Only'));
      expect(AmountToWords.convert(99999),
          equals('Ninety Nine Thousand Nine Hundred Ninety Nine Rupees Only'));
    });

    test('converts lakhs (Indian system)', () {
      expect(AmountToWords.convert(100000), equals('One Lakh Rupees Only'));
      expect(
          AmountToWords.convert(150000), equals('One Lakh Fifty Thousand Rupees Only'));
      expect(AmountToWords.convert(999999),
          equals(
              'Nine Lakh Ninety Nine Thousand Nine Hundred Ninety Nine Rupees Only'));
    });

    test('converts crores (Indian system)', () {
      expect(
          AmountToWords.convert(10000000), equals('One Crore Rupees Only'));
      expect(AmountToWords.convert(15000000),
          equals('One Crore Fifty Lakh Rupees Only'));
    });

    // ─── AKTS Membership Amount Fixtures ─────────────────────────────────

    test('converts typical AKTS membership amount (500)', () {
      expect(
        AmountToWords.convert(500),
        equals('Five Hundred Rupees Only'),
      );
    });

    test('converts typical AKTS membership amount (1000)', () {
      expect(
        AmountToWords.convert(1000),
        equals('One Thousand Rupees Only'),
      );
    });

    // ─── Decimal Handling ────────────────────────────────────────────────

    test('handles decimal amounts', () {
      final result = AmountToWords.convert(500.50);
      expect(result.contains('Five Hundred'), isTrue);
      expect(result.contains('Fifty Paise'), isTrue);
    });

    test('handles .00 amounts (no paise)', () {
      expect(AmountToWords.convert(500.00), equals('Five Hundred Rupees Only'));
    });

    // ─── Static Wrapper ───────────────────────────────────────────────────

    test('static convert method produces correct output', () {
      final result = AmountToWords.convert(250.75);
      expect(result, isNotEmpty);
      expect(result, contains('Two Hundred'));
      expect(result, contains('Seventy Five Paise'));
    });
  });
}
