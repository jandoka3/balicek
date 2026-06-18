import 'package:balici_appka/logic/import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseImport', () {
    test('jen řádky', () {
      expect(parseImport('Tričko\nKalhoty\nBunda'),
          ['Tričko', 'Kalhoty', 'Bunda']);
    });

    test('jen čárky', () {
      expect(parseImport('Tričko, Kalhoty, Bunda'),
          ['Tričko', 'Kalhoty', 'Bunda']);
    });

    test('mix řádků a čárek', () {
      expect(parseImport('Tričko, Kalhoty\nBunda,Čepice'),
          ['Tričko', 'Kalhoty', 'Bunda', 'Čepice']);
    });

    test('prázdné řádky se zahodí', () {
      expect(parseImport('Tričko\n\n\nKalhoty\n'),
          ['Tričko', 'Kalhoty']);
    });

    test('mezery okolo se ořežou', () {
      expect(parseImport('  Tričko  ,   Kalhoty   '),
          ['Tričko', 'Kalhoty']);
    });

    test('duplicity (case-insensitive) se zahodí, první zůstává', () {
      expect(parseImport('Tričko\ntričko\nTRIČKO\nKalhoty'),
          ['Tričko', 'Kalhoty']);
    });

    test('prázdný vstup vrací prázdný seznam', () {
      expect(parseImport(''), <String>[]);
      expect(parseImport('   \n , \n'), <String>[]);
    });
  });
}
