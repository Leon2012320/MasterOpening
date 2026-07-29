import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/san_notation.dart';

void main() {
  group('localize', () {
    test('setzt deutsche Figurenbuchstaben', () {
      expect(SanNotation.localize('Nf3', 'de'), 'Sf3');
      expect(SanNotation.localize('Bb5', 'de'), 'Lb5');
      expect(SanNotation.localize('Rxh8', 'de'), 'Txh8');
      expect(SanNotation.localize('Qd1+', 'de'), 'Dd1+');
      expect(SanNotation.localize('Kg1', 'de'), 'Kg1');
    });

    test('lässt Bauernzüge und Rochade unverändert', () {
      expect(SanNotation.localize('e4', 'de'), 'e4');
      expect(SanNotation.localize('exd5', 'de'), 'exd5');
      expect(SanNotation.localize('O-O', 'de'), 'O-O');
      expect(SanNotation.localize('O-O-O+', 'de'), 'O-O-O+');
    });

    test('verwechselt Linienbuchstaben nicht mit Figuren', () {
      // Das kleine b ist die b-Linie, kein Läufer.
      expect(SanNotation.localize('bxc3', 'de'), 'bxc3');
      // Das grosse B am Anfang schon.
      expect(SanNotation.localize('Bxc3', 'de'), 'Lxc3');
    });

    test('übersetzt die Umwandlungsfigur', () {
      expect(SanNotation.localize('e8=Q+', 'de'), 'e8=D+');
      expect(SanNotation.localize('bxa1=N', 'de'), 'bxa1=S');
    });

    test('behält die Unterscheidung bei mehrdeutigen Zügen', () {
      expect(SanNotation.localize('Nbd2', 'de'), 'Sbd2');
      expect(SanNotation.localize('R1e2', 'de'), 'T1e2');
      expect(SanNotation.localize('Qh4xe1#', 'de'), 'Dh4xe1#');
    });

    test('lässt Englisch unverändert', () {
      for (final san in ['Nf3', 'Bb5', 'e8=Q', 'O-O']) {
        expect(SanNotation.localize(san, 'en'), san);
      }
    });

    test('lässt unbekannte Sprachen unverändert', () {
      expect(SanNotation.localize('Nf3', 'fr'), 'Nf3');
    });
  });

  group('normalize', () {
    test('macht aus deutscher Eingabe wieder Standard-SAN', () {
      expect(SanNotation.normalize('Sf3', 'de'), 'Nf3');
      expect(SanNotation.normalize('Lxc3', 'de'), 'Bxc3');
      expect(SanNotation.normalize('e8=D+', 'de'), 'e8=Q+');
      expect(SanNotation.normalize('bxc3', 'de'), 'bxc3');
    });

    test('ist die Umkehrung von localize', () {
      const sans = ['Nf3', 'Bb5', 'Rxh8', 'Qd1+', 'e8=Q', 'O-O', 'bxc3'];
      for (final san in sans) {
        expect(
          SanNotation.normalize(SanNotation.localize(san, 'de'), 'de'),
          san,
          reason: san,
        );
      }
    });
  });

  test('sideLabel folgt der Sprache', () {
    expect(SanNotation.sideLabel(Side.white, 'de'), 'Weiß');
    expect(SanNotation.sideLabel(Side.black, 'en'), 'Black');
  });

  group('moveNumberLabel', () {
    test('nummeriert weisse Züge', () {
      expect(
        SanNotation.moveNumberLabel(1, forceBlackEllipsis: false),
        '1.',
      );
      expect(
        SanNotation.moveNumberLabel(5, forceBlackEllipsis: false),
        '3.',
      );
    });

    test('setzt Auslassungspunkte nur, wenn Schwarz eine Zeile beginnt', () {
      expect(SanNotation.moveNumberLabel(2, forceBlackEllipsis: true), '1…');
      expect(SanNotation.moveNumberLabel(2, forceBlackEllipsis: false), '');
    });
  });
}
