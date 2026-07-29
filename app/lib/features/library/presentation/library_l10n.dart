import 'package:masteropening/features/library/domain/library_opening.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Übersetzungen für die Werte aus den Bibliotheksdaten.
///
/// Die Daten selbst führen nur Bezeichner (`theoryHeavy`, `difficulty: 4`);
/// die Beschriftung gehört in die ARB-Dateien und nicht in die Assets — sonst
/// müsste eine neue Sprache die gesamte Bibliothek neu erzeugen.
extension LibraryL10n on AppL10n {
  String openingTag(OpeningTag tag) => switch (tag) {
    OpeningTag.attacking => tagAttacking,
    OpeningTag.solid => tagSolid,
    OpeningTag.tactical => tagTactical,
    OpeningTag.positional => tagPositional,
    OpeningTag.open => tagOpen,
    OpeningTag.closed => tagClosed,
    OpeningTag.gambit => tagGambit,
    OpeningTag.system => tagSystem,
    OpeningTag.classical => tagClassical,
    OpeningTag.modern => tagModern,
    OpeningTag.flexible => tagFlexible,
    OpeningTag.universal => tagUniversal,
    OpeningTag.beginnerFriendly => tagBeginnerFriendly,
    OpeningTag.theoryLight => tagTheoryLight,
    OpeningTag.theoryHeavy => tagTheoryHeavy,
  };

  String openingDifficulty(int level) => switch (level) {
    1 => libraryDifficulty1,
    2 => libraryDifficulty2,
    3 => libraryDifficulty3,
    4 => libraryDifficulty4,
    _ => libraryDifficulty5,
  };
}
