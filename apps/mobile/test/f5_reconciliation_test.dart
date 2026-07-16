// F5 reconciliation coverage: the pure logic ported from the Swift oracle, plus a lock on the
// Lithuanian plural forms (the classic `few` (2–9) miss). No network, no DB.
import 'package:brickback/core/display_name.dart';
import 'package:brickback/features/catalog/catalog_models.dart';
import 'package:brickback/l10n/app_localizations_lt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SetLifecycle.fromRaw', () {
    test('maps the catalog status strings', () {
      expect(SetLifecycle.fromRaw('upcoming'), SetLifecycle.upcoming);
      expect(SetLifecycle.fromRaw('available'), SetLifecycle.available);
      expect(SetLifecycle.fromRaw('retiring_soon'), SetLifecycle.retiringSoon);
      expect(SetLifecycle.fromRaw('retired'), SetLifecycle.retired);
    });
    test('null / unknown → null', () {
      expect(SetLifecycle.fromRaw(null), isNull);
      expect(SetLifecycle.fromRaw(''), isNull);
      expect(SetLifecycle.fromRaw('bananas'), isNull);
    });
  });

  group('SetPrice.hasAny', () {
    test('true when either side is present', () {
      expect(const SetPrice(newValue: 1, used: null, currency: 'EUR').hasAny, isTrue);
      expect(const SetPrice(newValue: null, used: 2, currency: 'EUR').hasAny, isTrue);
    });
    test('false when neither side is present', () {
      expect(const SetPrice(newValue: null, used: null, currency: 'EUR').hasAny, isFalse);
    });
  });

  group('NameGenerator', () {
    test('produces a two-word "<Adjective> <Noun>" name', () {
      for (var i = 0; i < 50; i++) {
        final name = NameGenerator.random();
        final parts = name.split(' ');
        expect(parts.length, 2, reason: 'name "$name" should be two words');
        expect(parts[0], isNotEmpty);
        expect(parts[1], isNotEmpty);
      }
    });
  });

  group('Lithuanian plurals (one / few / other)', () {
    final lt = AppLocalizationsLt();
    // Lithuanian: one = n%10==1 && n%100!=11 (1, 21); few = n%10 in 2..9 && n%100 not in 11..19
    // (2, 5); other = the rest (0, 10, 11..19). The `few` (2–9) category is the classic miss.
    test('partsCount at 0, 1, 2, 5, 10, 21', () {
      expect(lt.partsCount(0), 'nėra dalių');
      expect(lt.partsCount(1), '1 dalis'); // one
      expect(lt.partsCount(2), '2 dalys'); // few
      expect(lt.partsCount(5), '5 dalys'); // few
      expect(lt.partsCount(10), '10 dalių'); // other
      expect(lt.partsCount(21), '21 dalis'); // one
    });
    test('partyMemberCount at 1, 2, 10, 21', () {
      expect(lt.partyMemberCount(1), '1 narys'); // one
      expect(lt.partyMemberCount(2), '2 nariai'); // few
      expect(lt.partyMemberCount(10), '10 narių'); // other
      expect(lt.partyMemberCount(21), '21 narys'); // one
    });
    test('uniquePartsCount at 2 and 5 uses the few form', () {
      expect(lt.uniquePartsCount(2), '2 unikalios dalys');
      expect(lt.uniquePartsCount(5), '5 unikalios dalys');
    });
  });
}
