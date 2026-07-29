// Die Bibliothekseintraege fuer Schwarz — Aufbau wie bei `openings.white.mjs`.

export const blackOpenings = [
  // ── Gegen 1.e4: Sizilianisch ───────────────────────────────────────────────
  {
    id: 'sicilian-najdorf',
    eco: 'B90',
    side: 'black',
    seed: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6',
    mainline: 'Be3 e5 Nb3 Be6 f3 Be7 Qd2 O-O',
    tags: ['attacking', 'tactical', 'open', 'theoryHeavy'],
    difficulty: 5,
    popularity: 94,
    de: {
      name: 'Sizilianisch — Najdorf',
      summary:
        'Der beruehmteste Sizilianer. a6 nimmt dem weissen Springer und Laeufer das Feld b5 und haelt sich alle Plaene offen. '
        + 'Sehr scharf und sehr theoretisch — dafuer die kaempferischste Antwort auf 1.e4.',
      plans: [
        'Mit e5 Raum im Zentrum nehmen und den Springer d4 vertreiben.',
        'Auf der halboffenen c-Linie mit Rc8 und Qc7 druecken.',
        'Bei langer Rochade des Gegners mit b5–b4 den Damenfluegel aufreissen.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 Be7 8. Qf3 Qc7 9. O-O-O Nbd7 10. g4 b5 11. Bxf6 Nxf6 12. g5 Nd7 13. f5 Bxg5+',
          why: 'Der Laeuferschlag auf g5 sieht aktiv aus, oeffnet aber die Linie zum eigenen Koenig.',
        },
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 Ng4 7. Bg5 h6 8. Bh4 g5 9. Bg3 Bg7 10. h3 Ne5 11. Nf5',
          why: 'Nach Ng4 muss Schwarz genau weiterspielen — sonst steht der Springer nur im Weg.',
        },
      ],
    },
    en: {
      name: 'Sicilian — Najdorf',
      summary:
        'The most famous Sicilian. a6 denies b5 to White’s knight and bishop and keeps every plan available. '
        + 'Very sharp and very theoretical — but the most combative answer to 1.e4.',
      plans: [
        'Take central space with e5 and chase the d4 knight.',
        'Press on the half-open c-file with Rc8 and Qc7.',
        'If White castles long, tear open the queenside with b5–b4.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 Be7 8. Qf3 Qc7 9. O-O-O Nbd7 10. g4 b5 11. Bxf6 Nxf6 12. g5 Nd7 13. f5 Bxg5+',
          why: 'Taking on g5 looks active but opens the file towards your own king.',
        },
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 Ng4 7. Bg5 h6 8. Bh4 g5 9. Bg3 Bg7 10. h3 Ne5 11. Nf5',
          why: 'After Ng4 Black must follow up precisely — otherwise the knight is just in the way.',
        },
      ],
    },
  },
  {
    id: 'sicilian-dragon',
    eco: 'B70',
    side: 'black',
    seed: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6',
    mainline: 'Be3 Bg7 f3 O-O Qd2 Nc6 Bc4 Bd7',
    tags: ['attacking', 'tactical', 'open', 'theoryHeavy'],
    difficulty: 5,
    popularity: 62,
    de: {
      name: 'Sizilianisch — Drachen',
      summary:
        'Der Laeufer auf g7 zielt ueber die lange Diagonale bis nach b2. '
        + 'Beide Seiten rochieren auf verschiedene Fluegel und stuermen — wer einen Zug schneller ist, gewinnt.',
      plans: [
        'Mit Rc8 und Nc4 oder Rxc3 den Damenfluegel des Gegners aufreissen.',
        'Den Laeufer g7 unter allen Umstaenden am Leben halten.',
        'Mit b5–b4 den Springer c3 vertreiben und die Diagonale oeffnen.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 O-O 8. Qd2 Nc6 9. Bc4 Bd7 10. O-O-O Rc8 11. Bb3 h5 12. h4 Ne5 13. Bg5 Rxc3 14. bxc3 Qc7 15. Ne2',
          why: 'Das Qualitaetsopfer auf c3 muss zum richtigen Zeitpunkt kommen — zu frueh verpufft es.',
        },
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 O-O 8. Qd2 Nc6 9. O-O-O d5 10. exd5 Nxd5 11. Nxc6 bxc6 12. Bd4 Bxd4 13. Qxd4',
          why: 'Den Drachenlaeufer abzutauschen nimmt der Stellung ihre Seele.',
        },
      ],
    },
    en: {
      name: 'Sicilian — Dragon',
      summary:
        'The g7 bishop looks all the way down to b2. '
        + 'Both sides castle on opposite wings and storm — whoever is one move faster wins.',
      plans: [
        'Rip open White’s queenside with Rc8 and Nc4 or Rxc3.',
        'Keep the g7 bishop alive at all costs.',
        'Chase the c3 knight with b5–b4 and open the diagonal.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 O-O 8. Qd2 Nc6 9. Bc4 Bd7 10. O-O-O Rc8 11. Bb3 h5 12. h4 Ne5 13. Bg5 Rxc3 14. bxc3 Qc7 15. Ne2',
          why: 'The exchange sacrifice on c3 must come at the right moment — too early it fizzles.',
        },
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 O-O 8. Qd2 Nc6 9. O-O-O d5 10. exd5 Nxd5 11. Nxc6 bxc6 12. Bd4 Bxd4 13. Qxd4',
          why: 'Trading the Dragon bishop takes the soul out of the position.',
        },
      ],
    },
  },
  {
    id: 'sicilian-accelerated-dragon',
    eco: 'B34',
    side: 'black',
    seed: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 g6',
    mainline: 'Nc3 Bg7 Be3 Nf6 Bc4 O-O Bb3 d6',
    tags: ['positional', 'open', 'flexible'],
    difficulty: 3,
    popularity: 48,
    de: {
      name: 'Sizilianisch — Beschleunigter Drache',
      summary:
        'Der Drachenlaeufer kommt ohne d6 aufs Brett, was Schwarz spaeter d7–d5 in einem Zug erlaubt. '
        + 'Dafuer muss man den Maroczy-Aufbau mit c4 aushalten.',
      plans: [
        'd7–d5 in einem Zug durchsetzen und ausgleichen.',
        'Gegen den Maroczy-Aufbau die Figuren abtauschen und auf b2 und d4 druecken.',
        'Den Laeufer g7 mit Qa5 und Rfc8 unterstuetzen.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 g6 5. Nxc6 bxc6 6. Qd4 f6 7. e5',
          why: 'Nach Nxc6 muss Schwarz mit dem b-Bauern schlagen und die Struktur akzeptieren.',
        },
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 g6 5. c4 Bg7 6. Be3 Nf6 7. Nc3 Ng4 8. Qxg4 Nxd4 9. Qd1 Ne6 10. Qd2',
          why: 'Der Doppelangriff mit Ng4 funktioniert nur, wenn Weiss ungenau spielt.',
        },
      ],
    },
    en: {
      name: 'Sicilian — Accelerated Dragon',
      summary:
        'The Dragon bishop appears without d6, letting Black play d7–d5 in one go later. '
        + 'The price is having to handle the Maroczy Bind with c4.',
      plans: [
        'Achieve d7–d5 in a single move and equalise.',
        'Against the Maroczy Bind, trade pieces and press on b2 and d4.',
        'Support the g7 bishop with Qa5 and Rfc8.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 g6 5. Nxc6 bxc6 6. Qd4 f6 7. e5',
          why: 'After Nxc6 Black has to recapture with the b-pawn and accept the structure.',
        },
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 g6 5. c4 Bg7 6. Be3 Nf6 7. Nc3 Ng4 8. Qxg4 Nxd4 9. Qd1 Ne6 10. Qd2',
          why: 'The Ng4 double attack only works if White plays inaccurately.',
        },
      ],
    },
  },
  {
    id: 'sicilian-sveshnikov',
    eco: 'B33',
    side: 'black',
    seed: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5',
    mainline: 'Ndb5 d6 Bg5 a6 Na3 b5 Nd5 Be7',
    tags: ['attacking', 'tactical', 'open', 'theoryHeavy'],
    difficulty: 5,
    popularity: 58,
    de: {
      name: 'Sizilianisch — Sweschnikow',
      summary:
        'Schwarz akzeptiert ein Loch auf d5 und einen Rueckstandsbauern, bekommt dafuer aber Figurenspiel und das Laeuferpaar. '
        + 'Eine der modernsten und kaempferischsten Antworten auf 1.e4.',
      plans: [
        'Mit f7–f5 den Springer d5 unter Druck setzen.',
        'Das Laeuferpaar behalten und die Diagonalen oeffnen.',
        'Auf der halboffenen c-Linie und mit b5–b4 am Damenfluegel spielen.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 a6',
          why: 'a6 sofort verliert einen Bauern nach Sd6+ — erst d6 muss kommen.',
        },
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Nf3',
          why: 'Weiss darf den Springer nicht passiv zurueckziehen; Ndb5 ist der ganze Punkt.',
        },
      ],
    },
    en: {
      name: 'Sicilian — Sveshnikov',
      summary:
        'Black accepts a hole on d5 and a backward pawn in return for piece play and the bishop pair. '
        + 'One of the most modern and combative answers to 1.e4.',
      plans: [
        'Pressure the d5 knight with f7–f5.',
        'Keep the bishop pair and open diagonals.',
        'Play on the half-open c-file and with b5–b4 on the queenside.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 a6',
          why: 'a6 at once drops a pawn to Nd6+ — d6 has to come first.',
        },
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Nf3',
          why: 'White must not retreat the knight passively; Ndb5 is the entire point.',
        },
      ],
    },
  },
  {
    id: 'sicilian-taimanov',
    eco: 'B46',
    side: 'black',
    seed: '1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6',
    mainline: 'Nc3 a6 Be2 Qc7 O-O Nf6 Be3 Bb4',
    tags: ['flexible', 'positional', 'open'],
    difficulty: 4,
    popularity: 60,
    de: {
      name: 'Sizilianisch — Taimanow',
      summary:
        'Schwarz haelt die Struktur maximal flexibel und entscheidet erst spaet, wo die Bauern hingehen. '
        + 'Weniger Auswendiglernen als im Najdorf, aber viel Verstaendnis noetig.',
      plans: [
        'Mit Qc7 und a6 den Damenfluegel vorbereiten, bevor die Bauern ziehen.',
        'Bei Gelegenheit d7–d5 in einem Zug spielen.',
        'Den Laeufer nach b4 stellen und den Springer c3 fesseln.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. Be3 Bb4 7. Ndb5',
          why: 'Lb4 zu frueh: nach Sdb5 muss die Dame ziehen und Schwarz verliert Zeit.',
        },
        {
          line: '1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nb5 a6 6. Nd6+',
          why: 'a6 zu frueh: Sd6+ ist ein starkes Schach, das die Struktur zerstoert.',
        },
      ],
    },
    en: {
      name: 'Sicilian — Taimanov',
      summary:
        'Black keeps the structure maximally flexible and decides late where the pawns go. '
        + 'Less memorisation than the Najdorf, but it demands understanding.',
      plans: [
        'Prepare the queenside with Qc7 and a6 before committing pawns.',
        'Play d7–d5 in one go when the chance comes.',
        'Put the bishop on b4 and pin the c3 knight.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. Be3 Bb4 7. Ndb5',
          why: 'Bb4 too early: after Ndb5 the queen must move and Black loses time.',
        },
        {
          line: '1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nb5 a6 6. Nd6+',
          why: 'a6 too early: Nd6+ is a strong check that wrecks the structure.',
        },
      ],
    },
  },

  // ── Gegen 1.e4: Franzoesisch, Caro-Kann und Co. ───────────────────────────
  {
    id: 'french-winawer',
    eco: 'C18',
    side: 'black',
    seed: '1. e4 e6 2. d4 d5 3. Nc3 Bb4',
    mainline: 'e5 c5 a3 Bxc3+ bxc3 Ne7 Qg4 Qc7',
    tags: ['tactical', 'closed', 'theoryHeavy'],
    difficulty: 4,
    popularity: 56,
    de: {
      name: 'Franzoesisch — Winawer',
      summary:
        'Schwarz gibt das Laeuferpaar und bekommt dafuer ein bleibendes Ziel: die weissen Doppelbauern auf c3. '
        + 'Unsymmetrisch, scharf und voller Gift auf beiden Seiten.',
      plans: [
        'Den Bauern c3 und die Kette d4–e5 mit c5 und Nc6 unter Druck setzen.',
        'Den Koenig oft in der Mitte lassen und stattdessen im Zentrum kontern.',
        'Auf der halboffenen c-Linie Turm und Dame aufbauen.',
      ],
      mistakes: [
        {
          line: '1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Ne7 7. Qg4 O-O',
          why: 'Kurz zu rochieren stellt den Koenig direkt in den weissen Angriff — Qc7 ist der Hauptzug.',
        },
        {
          line: '1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Ba5 6. b4 cxd4 7. Qg4 Ne7 8. bxa5 dxc3 9. Qxg7 Rg8 10. Qxh7 Nbc6 11. Nf3 Qxa5 12. Bd2',
          why: 'Den Laeufer auf a5 zu halten kostet Material, wenn Schwarz die Folgezuege nicht kennt.',
        },
      ],
    },
    en: {
      name: 'French — Winawer',
      summary:
        'Black gives up the bishop pair for a permanent target: White’s doubled pawns on c3. '
        + 'Unbalanced, sharp and full of poison on both sides.',
      plans: [
        'Pressure the c3 pawn and the d4–e5 chain with c5 and Nc6.',
        'Often leave the king in the centre and counter there instead.',
        'Build up rook and queen on the half-open c-file.',
      ],
      mistakes: [
        {
          line: '1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Ne7 7. Qg4 O-O',
          why: 'Castling short walks straight into White’s attack — Qc7 is the main move.',
        },
        {
          line: '1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Ba5 6. b4 cxd4 7. Qg4 Ne7 8. bxa5 dxc3 9. Qxg7 Rg8 10. Qxh7 Nbc6 11. Nf3 Qxa5 12. Bd2',
          why: 'Keeping the bishop on a5 costs material unless Black knows the follow-up.',
        },
      ],
    },
  },
  {
    id: 'french-classical',
    eco: 'C11',
    side: 'black',
    seed: '1. e4 e6 2. d4 d5 3. Nc3 Nf6',
    mainline: 'e5 Nfd7 f4 c5 Nf3 Nc6 Be3 cxd4',
    tags: ['solid', 'closed', 'positional'],
    difficulty: 3,
    popularity: 52,
    de: {
      name: 'Franzoesisch — Klassisch',
      summary:
        'Der natuerliche Aufbau: Nf6 greift e4 an und zwingt Weiss zu einer Entscheidung. '
        + 'Solide, mit klaren Plaenen gegen die weisse Bauernkette.',
      plans: [
        'Mit c7–c5 und f7–f6 die Kette d4–e5 an ihrer Basis angreifen.',
        'Den Laeufer c8 ueber d7–b5 oder nach a6 aus dem Gefaengnis holen.',
        'Auf der c-Linie und gegen d4 Druck aufbauen.',
      ],
      mistakes: [
        {
          line: '1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. e5 Nfd7 5. f4 c5 6. Nf3 Nc6 7. Be3 Qb6 8. Na4 Qa5+ 9. c3 cxd4 10. b4 Nxb4 11. cxb4 Bxb4+ 12. Bd2 Bxd2+ 13. Nxd2 b6',
          why: 'Das Figurenopfer auf b4 ist eine bekannte Falle, die nur bei ungenauem Weiss aufgeht.',
        },
        {
          line: '1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. Bg5 dxe4 5. Nxe4 Be7 6. Bxf6 gxf6 7. Nf3 f5 8. Nc3 Bf6 9. g3 O-O',
          why: 'Kurz zu rochieren nach gxf6 stellt den Koenig auf die offene g-Linie.',
        },
      ],
    },
    en: {
      name: 'French — Classical',
      summary:
        'The natural setup: Nf6 hits e4 and forces White to commit. '
        + 'Solid, with clear plans against White’s pawn chain.',
      plans: [
        'Attack the base of the d4–e5 chain with c7–c5 and f7–f6.',
        'Free the c8 bishop via d7–b5 or to a6.',
        'Build pressure on the c-file and against d4.',
      ],
      mistakes: [
        {
          line: '1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. e5 Nfd7 5. f4 c5 6. Nf3 Nc6 7. Be3 Qb6 8. Na4 Qa5+ 9. c3 cxd4 10. b4 Nxb4 11. cxb4 Bxb4+ 12. Bd2 Bxd2+ 13. Nxd2 b6',
          why: 'The piece sacrifice on b4 is a known trap that only works against imprecise play.',
        },
        {
          line: '1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. Bg5 dxe4 5. Nxe4 Be7 6. Bxf6 gxf6 7. Nf3 f5 8. Nc3 Bf6 9. g3 O-O',
          why: 'Castling short after gxf6 puts the king on the open g-file.',
        },
      ],
    },
  },
  {
    id: 'caro-kann-classical',
    eco: 'B18',
    side: 'black',
    seed: '1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5',
    mainline: 'Ng3 Bg6 h4 h6 Nf3 Nd7 h5 Bh7 Bd3 Bxd3 Qxd3 e6',
    extraLines: {
      'Ng3 Bg6 h4 h6 Nf3 Nd7 h5 Bh7 Bd3 Bxd3 Qxd3 Ngf6 Bd2 e6 O-O-O Qc7':
        'Hauptvariante mit langer Rochade',
      'Ng3 Bg6 Nh3 Nf6 Nf4 e5 Nxg6 hxg6': 'Sh3 gegen den Laeufer',
      'Ng3 Bg6 h4 h6 Nf3 e6 Ne5 Bh7 Bd3 Bxd3 Qxd3': 'Frueher Springer auf e5',
      'Ng3 Bg6 h4 h5 Nf3 Nd7 Bd3 Bxd3 Qxd3 e6': 'h5 statt h6',
      'Ng3 Bg6 f4 e6 Nf3 Bd6 Bd3 Bxd3 Qxd3 Ne7': 'Weiss stuermt mit f4',
    },
    tags: ['solid', 'positional', 'beginnerFriendly'],
    difficulty: 3,
    popularity: 70,
    de: {
      name: 'Caro-Kann — Klassisch',
      summary:
        'Schwarz entwickelt den Laeufer c8 vor e7–e6 und loest damit das Hauptproblem franzoesischer Stellungen. '
        + 'Sehr solide Struktur ohne Schwaechen.',
      plans: [
        'Den Laeufer gegen den weissen Laeufer d3 abtauschen.',
        'Mit c6–c5 im richtigen Moment das Zentrum angreifen.',
        'Lang rochieren, wenn Weiss am Koenigsfluegel stuermt.',
      ],
      mistakes: [
        {
          line: '1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. h4 h5',
          why: 'h5 statt h6 schwaecht g5 dauerhaft und laesst den Springer nach f4.',
        },
        {
          line: '1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7 5. Qe2 Ngf6 6. Nd6#',
          why: 'Das beruehmte Matt in sechs Zuegen: Ngf6 verstellt der Dame das Feld e7.',
        },
      ],
    },
    en: {
      name: 'Caro-Kann — Classical',
      summary:
        'Black develops the c8 bishop before e7–e6, solving the main problem of French structures. '
        + 'A very solid structure with no weaknesses.',
      plans: [
        'Trade the bishop for White’s light-squared bishop on d3.',
        'Hit the centre with c6–c5 at the right moment.',
        'Castle long if White storms the kingside.',
      ],
      mistakes: [
        {
          line: '1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. h4 h5',
          why: 'h5 instead of h6 permanently weakens g5 and invites the knight to f4.',
        },
        {
          line: '1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7 5. Qe2 Ngf6 6. Nd6#',
          why: 'The famous six-move mate: Ngf6 blocks the queen’s escape on e7.',
        },
      ],
    },
  },
  {
    id: 'caro-kann-karpov',
    eco: 'B17',
    side: 'black',
    seed: '1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7',
    mainline: 'Nf3 Ngf6 Nxf6+ Nxf6 c3 Bg4 Be2 e6 O-O Be7',
    extraLines: {
      'Ng3 Ngf6 Nf3 e6 Bd3 c5 O-O Be7': 'Sg3 statt Abtausch',
      'Nf3 Ngf6 Nxf6+ exf6 Bc4 Bd6 Qe2+ Qe7': 'Mit dem e-Bauern zurueckschlagen',
      'Bc4 Ngf6 Ng5 e6 Qe2 Nb6 Bd3 h6 N5f3 c5': 'Der Angriff auf f7',
      'Nf3 Ngf6 Nxf6+ Nxf6 Ne5 Be6 c3 g6 Bd3 Bg7': 'Springer auf e5',
      'Nf3 Ngf6 Bd3 Nxe4 Bxe4 Nf6 Bd3 Bg4': 'Weiss haelt den Springer',
    },
    tags: ['solid', 'positional', 'flexible'],
    difficulty: 3,
    popularity: 54,
    de: {
      name: 'Caro-Kann — Karpow-Variante',
      summary:
        'Nd7 bereitet Ngf6 vor, ohne dass der Springer auf f6 abgetauscht und die Bauernstruktur zerstoert wird. '
        + 'Karpows Lieblingsaufbau: unauffaellig, zaeh und schwer zu knacken.',
      plans: [
        'Mit c6–c5 den weissen Zentrumsbauern angreifen.',
        'Die Struktur sauber halten und im Endspiel den besseren Bauern zeigen.',
        'Den Laeufer nach d6 oder e7 entwickeln und schnell rochieren.',
      ],
      mistakes: [
        {
          line: '1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7 5. Ng5 Ngf6 6. Bd3 e6 7. N1f3 h6 8. Nxe6',
          why: 'Das Springeropfer auf e6 ist eine bekannte Falle — nach fxe6 muss Schwarz genau verteidigen.',
        },
        {
          line: '1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7 5. Nf3 Ngf6 6. Nxf6+ gxf6',
          why: 'Mit dem g-Bauern zurueckzuschlagen widerspricht dem Sinn der ganzen Variante.',
        },
      ],
    },
    en: {
      name: 'Caro-Kann — Karpov Variation',
      summary:
        'Nd7 prepares Ngf6 without allowing the knight to be traded and the structure wrecked. '
        + 'Karpov’s favourite: unassuming, resilient and hard to crack.',
      plans: [
        'Attack White’s centre pawn with c6–c5.',
        'Keep the structure clean and show the better pawns in the endgame.',
        'Develop the bishop to d6 or e7 and castle quickly.',
      ],
      mistakes: [
        {
          line: '1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7 5. Ng5 Ngf6 6. Bd3 e6 7. N1f3 h6 8. Nxe6',
          why: 'The knight sacrifice on e6 is a known trap — after fxe6 Black must defend precisely.',
        },
        {
          line: '1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7 5. Nf3 Ngf6 6. Nxf6+ gxf6',
          why: 'Recapturing with the g-pawn defeats the whole point of the variation.',
        },
      ],
    },
  },
  {
    id: 'scandinavian-black',
    eco: 'B01',
    side: 'black',
    seed: '1. e4 d5 2. exd5 Qxd5 3. Nc3 Qa5',
    mainline: 'd4 Nf6 Nf3 c6 Bc4 Bf5 Bd2 e6 Nd5 Qd8',
    tags: ['theoryLight', 'solid', 'beginnerFriendly'],
    difficulty: 2,
    popularity: 42,
    de: {
      name: 'Skandinavische Verteidigung',
      summary:
        'Schwarz tauscht sofort im Zentrum und holt den Bauern mit der Dame zurueck. '
        + 'Wenig Theorie, immer dieselbe Struktur — ideal fuer den Einstieg gegen 1.e4.',
      plans: [
        'Mit c6 und Bf5 ein Caro-Kann-aehnliches Bild aufbauen.',
        'Die Dame auf a5 oder d6 sicher parken und dann normal entwickeln.',
        'Lang rochieren und auf der d-Linie kontern.',
      ],
      mistakes: [
        {
          line: '1. e4 d5 2. exd5 Qxd5 3. Nc3 Qe5+',
          why: 'Das Schach bringt nichts und stellt die Dame auf ein Feld, von dem sie vertrieben wird.',
        },
        {
          line: '1. e4 d5 2. exd5 Qxd5 3. Nc3 Qa5 4. d4 c6 5. Nf3 Bg4 6. Bf4 e6 7. h3 Bxf3 8. Qxf3 Qb6 9. Bxb8',
          why: 'Der Doppelangriff auf b2 und d4 uebersieht, dass der Springer b8 haengt.',
        },
      ],
    },
    en: {
      name: 'Scandinavian Defence',
      summary:
        'Black trades in the centre at once and recaptures with the queen. '
        + 'Little theory, always the same structure — an ideal first answer to 1.e4.',
      plans: [
        'Build a Caro-Kann-like picture with c6 and Bf5.',
        'Park the queen safely on a5 or d6, then develop normally.',
        'Castle long and counter on the d-file.',
      ],
      mistakes: [
        {
          line: '1. e4 d5 2. exd5 Qxd5 3. Nc3 Qe5+',
          why: 'The check achieves nothing and puts the queen on a square she will be chased from.',
        },
        {
          line: '1. e4 d5 2. exd5 Qxd5 3. Nc3 Qa5 4. d4 c6 5. Nf3 Bg4 6. Bf4 e6 7. h3 Bxf3 8. Qxf3 Qb6 9. Bxb8',
          why: 'The double attack on b2 and d4 overlooks that the b8 knight hangs.',
        },
      ],
    },
  },
  {
    id: 'pirc-defence',
    eco: 'B07',
    side: 'black',
    seed: '1. e4 d6 2. d4 Nf6 3. Nc3 g6',
    mainline: 'Nf3 Bg7 Be2 O-O O-O Nc6 d5 Nb8',
    tags: ['modern', 'flexible', 'closed'],
    difficulty: 3,
    popularity: 38,
    de: {
      name: 'Pirc-Verteidigung',
      summary:
        'Schwarz laesst Weiss das Zentrum bauen und greift es spaeter mit Figuren und c5 oder e5 an. '
        + 'Hypermodern: erst entwickeln, dann kontern.',
      plans: [
        'Mit e7–e5 oder c7–c5 das weisse Zentrum untergraben.',
        'Den Laeufer g7 auf der langen Diagonale zur Wirkung bringen.',
        'Den Springer nach c6 oder d7 stellen und den Druck auf d4 erhoehen.',
      ],
      mistakes: [
        {
          line: '1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. Be3 Bg7 5. Qd2 c6 6. f3 b5 7. Nge2 Nbd7 8. Bh6 Bxh6 9. Qxh6',
          why: 'Den Laeufer g7 abzutauschen laesst die dunklen Felder um den Koenig ungedeckt.',
        },
        {
          line: '1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. f4 Bg7 5. Nf3 O-O 6. e5 dxe5 7. fxe5 Nd5 8. Nxd5 Qxd5 9. c4',
          why: 'Die Dame nach d5 zu bringen kostet Zeit — hier verliert Schwarz mehrere Tempi.',
        },
      ],
    },
    en: {
      name: 'Pirc Defence',
      summary:
        'Black lets White build the centre and attacks it later with pieces plus c5 or e5. '
        + 'Hypermodern: develop first, counter second.',
      plans: [
        'Undermine White’s centre with e7–e5 or c7–c5.',
        'Bring the g7 bishop to life on the long diagonal.',
        'Post the knight on c6 or d7 and increase pressure on d4.',
      ],
      mistakes: [
        {
          line: '1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. Be3 Bg7 5. Qd2 c6 6. f3 b5 7. Nge2 Nbd7 8. Bh6 Bxh6 9. Qxh6',
          why: 'Trading the g7 bishop leaves the dark squares around the king undefended.',
        },
        {
          line: '1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. f4 Bg7 5. Nf3 O-O 6. e5 dxe5 7. fxe5 Nd5 8. Nxd5 Qxd5 9. c4',
          why: 'Bringing the queen to d5 costs time — Black loses several tempi here.',
        },
      ],
    },
  },
  {
    id: 'petrov-defence',
    eco: 'C42',
    side: 'black',
    seed: '1. e4 e5 2. Nf3 Nf6',
    mainline: 'Nxe5 d6 Nf3 Nxe4 d4 d5 Bd3 Nc6 O-O Be7',
    tags: ['solid', 'positional', 'open'],
    difficulty: 3,
    popularity: 50,
    de: {
      name: 'Russische Verteidigung (Petrow)',
      summary:
        'Statt den Bauern e5 zu decken, greift Schwarz symmetrisch e4 an. '
        + 'Der Ruf als Remis-Eroeffnung taeuscht: die Stellungen sind ausgeglichen, aber keineswegs leblos.',
      plans: [
        'Den Springer auf e4 halten und mit d5 stuetzen.',
        'Schnell entwickeln und den Laeufer nach e7 oder d6 stellen.',
        'Die e-Linie mit Re8 besetzen.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nf3 Nf6 3. Nxe5 Nxe4',
          why: 'Sofort zurueckzuschlagen verliert Material: 4. Qe2 Qe7 5. Qxe4 kommt mit Doppelangriff.',
        },
        {
          line: '1. e4 e5 2. Nf3 Nf6 3. d4 exd4 4. e5 Ne4 5. Qxd4 d5 6. exd6 Nxd6 7. Nc3 Nc6 8. Qf4 g6 9. Bd2 Bg7',
          why: 'Der Springer auf e4 steht schoen, ist ohne Deckung aber nur ein Zug lang stark.',
        },
      ],
    },
    en: {
      name: 'Petrov Defence',
      summary:
        'Instead of defending e5, Black attacks e4 symmetrically. '
        + 'Its drawish reputation is misleading: the positions are balanced but far from lifeless.',
      plans: [
        'Keep the knight on e4, supported by d5.',
        'Develop quickly and place the bishop on e7 or d6.',
        'Occupy the e-file with Re8.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nf3 Nf6 3. Nxe5 Nxe4',
          why: 'Recapturing at once loses material: 4. Qe2 Qe7 5. Qxe4 comes with a double attack.',
        },
        {
          line: '1. e4 e5 2. Nf3 Nf6 3. d4 exd4 4. e5 Ne4 5. Qxd4 d5 6. exd6 Nxd6 7. Nc3 Nc6 8. Qf4 g6 9. Bd2 Bg7',
          why: 'The knight looks good on e4 but is only strong for one move without support.',
        },
      ],
    },
  },
  {
    id: 'berlin-defence',
    eco: 'C65',
    side: 'black',
    seed: '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6',
    mainline: 'O-O Nxe4 d4 Nd6 Bxc6 dxc6 dxe5 Nf5 Qxd8+ Kxd8',
    tags: ['solid', 'positional', 'theoryHeavy'],
    difficulty: 4,
    popularity: 66,
    de: {
      name: 'Berliner Verteidigung',
      summary:
        'Die „Berliner Mauer": Schwarz geht frueh ins Endspiel, verliert die Rochade und steht trotzdem bombenfest. '
        + 'Kramniks Waffe gegen Kasparow 2000 — seither Standard auf hoechster Ebene.',
      plans: [
        'Das Laeuferpaar behalten und den Koenig zu Fuss in Sicherheit bringen.',
        'Die Doppelbauern auf c6 und c7 als Bollwerk nutzen, nicht als Schwaeche sehen.',
        'Mit Be6, Kc8 und Bd6 in Ruhe konsolidieren.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 exd4',
          why: 'Den Bauern zu nehmen laesst Weiss nach Re1 mit grosser Initiative durchbrechen.',
        },
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. Re1 Nd6 6. Nxe5 Be7 7. Bf1 Nxe5 8. Rxe5 O-O 9. d4 Bf6 10. Re1 Re8',
          why: 'Der Abtausch auf e5 ohne Bf1 abzuwarten kostet einen Bauern.',
        },
      ],
    },
    en: {
      name: 'Berlin Defence',
      summary:
        'The “Berlin Wall”: Black heads for an early endgame, gives up castling and is still rock solid. '
        + 'Kramnik’s weapon against Kasparov in 2000 — a top-level standard ever since.',
      plans: [
        'Keep the bishop pair and walk the king to safety.',
        'Treat the doubled c-pawns as a bulwark, not a weakness.',
        'Consolidate calmly with Be6, Kc8 and Bd6.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 exd4',
          why: 'Taking the pawn lets White break through with Re1 and a huge initiative.',
        },
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. Re1 Nd6 6. Nxe5 Be7 7. Bf1 Nxe5 8. Rxe5 O-O 9. d4 Bf6 10. Re1 Re8',
          why: 'Trading on e5 without waiting for Bf1 costs a pawn.',
        },
      ],
    },
  },

  // ── Gegen 1.d4 ────────────────────────────────────────────────────────────
  {
    id: 'kings-indian-defence',
    eco: 'E60',
    side: 'black',
    seed: '1. d4 Nf6 2. c4 g6 3. Nc3 Bg7',
    mainline: 'e4 d6 Nf3 O-O Be2 e5 O-O Nc6 d5 Ne7',
    tags: ['attacking', 'closed', 'tactical', 'theoryHeavy'],
    difficulty: 4,
    popularity: 78,
    de: {
      name: 'Koenigsindische Verteidigung',
      summary:
        'Schwarz gibt das Zentrum ab und stuermt spaeter mit f5–f4–g5 am Koenigsfluegel. '
        + 'Eine der kaempferischsten Eroeffnungen ueberhaupt — Remis ist hier selten.',
      plans: [
        'Mit f7–f5 und g6–g5 den Koenigsfluegel aufreissen.',
        'Den Springer ueber e7 oder d7 nach f6 und h5 umgruppieren.',
        'Das Zentrum geschlossen halten, damit der Gegenangriff Zeit hat.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O exd4 8. Nxd4',
          why: 'Der Abtausch auf d4 gibt die Spannung auf, aus der der Koenigsfluegelangriff lebt.',
        },
        {
          line: '1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. f4 O-O 6. Nf3 c5 7. d5 e6 8. Be2 exd5 9. cxd5 Bg4 10. O-O Nbd7 11. h3 Bxf3 12. Bxf3 a6 13. a4 Qc7 14. e5',
          why: 'Gegen den Vier-Bauern-Angriff muss Schwarz sofort kontern; passives Spiel wird ueberrollt.',
        },
      ],
    },
    en: {
      name: 'King’s Indian Defence',
      summary:
        'Black concedes the centre and later storms the kingside with f5–f4–g5. '
        + 'One of the most combative openings there is — draws are rare here.',
      plans: [
        'Tear open the kingside with f7–f5 and g6–g5.',
        'Regroup the knight via e7 or d7 to f6 and h5.',
        'Keep the centre closed so the counterattack has time.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O exd4 8. Nxd4',
          why: 'Trading on d4 releases the tension the kingside attack lives on.',
        },
        {
          line: '1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. f4 O-O 6. Nf3 c5 7. d5 e6 8. Be2 exd5 9. cxd5 Bg4 10. O-O Nbd7 11. h3 Bxf3 12. Bxf3 a6 13. a4 Qc7 14. e5',
          why: 'Against the Four Pawns Attack Black must counter immediately; passive play gets steamrolled.',
        },
      ],
    },
  },
  {
    id: 'nimzo-indian',
    eco: 'E20',
    side: 'black',
    seed: '1. d4 Nf6 2. c4 e6 3. Nc3 Bb4',
    mainline: 'e3 O-O Bd3 d5 Nf3 c5 O-O Nc6',
    tags: ['positional', 'solid', 'classical', 'theoryHeavy'],
    difficulty: 4,
    popularity: 86,
    de: {
      name: 'Nimzoindische Verteidigung',
      summary:
        'Der Laeufer fesselt den Springer c3 und kaempft um das Feld e4. '
        + 'Die vielleicht beste Antwort auf 1.d4 — solide, flexibel und auf jedem Niveau spielbar.',
      plans: [
        'Bei Bxc3 die weissen Doppelbauern zum Dauerziel machen.',
        'Mit d5 und c5 im Zentrum gegenhalten.',
        'Den Laeufer c8 nach b7 fianchettieren und e4 kontrollieren.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 O-O 5. a3 Bxc3+ 6. Qxc3 b6 7. Bg5 Bb7 8. f3 h6 9. Bh4 d5 10. e3 Nbd7 11. cxd5 Nxd5 12. Bxd8',
          why: 'Nach Bh4 ist die Dame gefesselt; Nxd5 uebersieht den Abzug auf d8.',
        },
        {
          line: '1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 b6 5. Nge2 Ba6 6. a3 Bxc3+ 7. Nxc3 d5 8. b3 O-O 9. a4',
          why: 'Den Laeufer freiwillig gegen den Springer abzutauschen, ohne Doppelbauern zu erzwingen, verschenkt den Sinn.',
        },
      ],
    },
    en: {
      name: 'Nimzo-Indian Defence',
      summary:
        'The bishop pins the c3 knight and fights for e4. '
        + 'Perhaps the best answer to 1.d4 — solid, flexible and playable at any level.',
      plans: [
        'If Bxc3 happens, make White’s doubled pawns a permanent target.',
        'Fight back in the centre with d5 and c5.',
        'Fianchetto the c8 bishop to b7 and control e4.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 O-O 5. a3 Bxc3+ 6. Qxc3 b6 7. Bg5 Bb7 8. f3 h6 9. Bh4 d5 10. e3 Nbd7 11. cxd5 Nxd5 12. Bxd8',
          why: 'After Bh4 the queen is pinned; Nxd5 misses the discovery on d8.',
        },
        {
          line: '1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 b6 5. Nge2 Ba6 6. a3 Bxc3+ 7. Nxc3 d5 8. b3 O-O 9. a4',
          why: 'Trading the bishop voluntarily without forcing doubled pawns throws away the point.',
        },
      ],
    },
  },
  {
    id: 'queens-gambit-declined',
    eco: 'D30',
    side: 'black',
    seed: '1. d4 d5 2. c4 e6',
    mainline: 'Nc3 Nf6 Bg5 Be7 e3 O-O Nf3 h6 Bh4 b6',
    tags: ['solid', 'classical', 'positional'],
    difficulty: 3,
    popularity: 82,
    de: {
      name: 'Damengambit — Abgelehnt',
      summary:
        'Der klassische Weg: Schwarz stuetzt d5 mit e6 und nimmt eine leicht passive, dafuer bombensichere Stellung. '
        + 'Fast unmoeglich zu ueberrennen.',
      plans: [
        'Den Laeufer c8 mit b6 und Bb7 oder ueber d7 entwickeln.',
        'Mit c7–c5 im richtigen Moment das Zentrum befreien.',
        'Bei Minoritaetsangriff die c-Linie besetzen und kontern.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 Be7 5. e3 O-O 6. Nf3 b6 7. cxd5 exd5 8. Bd3 Bb7 9. O-O Nbd7 10. Qc2 c5 11. Rad1 Ne4 12. Bf4',
          why: 'b6 zu frueh: der Laeufer auf b7 beisst nach cxd5 exd5 auf Granit.',
        },
        {
          line: '1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. cxd5 exd5 5. Bg5 c6 6. Qc2 Be7 7. e3 Nbd7 8. Bd3 O-O 9. Nf3 Re8 10. O-O Nf8 11. h3 Ne4 12. Bxe7 Qxe7 13. Bxe4 dxe4 14. Nd2',
          why: 'Den Abtausch auf e4 zuzulassen gibt Weiss das bessere Endspiel.',
        },
      ],
    },
    en: {
      name: 'Queen’s Gambit Declined',
      summary:
        'The classical route: Black supports d5 with e6 and takes a slightly passive but rock-solid position. '
        + 'Almost impossible to overrun.',
      plans: [
        'Develop the c8 bishop with b6 and Bb7, or via d7.',
        'Free the position with c7–c5 at the right moment.',
        'Against the minority attack, occupy the c-file and counter.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 Be7 5. e3 O-O 6. Nf3 b6 7. cxd5 exd5 8. Bd3 Bb7 9. O-O Nbd7 10. Qc2 c5 11. Rad1 Ne4 12. Bf4',
          why: 'b6 too early: after cxd5 exd5 the b7 bishop bites on granite.',
        },
        {
          line: '1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. cxd5 exd5 5. Bg5 c6 6. Qc2 Be7 7. e3 Nbd7 8. Bd3 O-O 9. Nf3 Re8 10. O-O Nf8 11. h3 Ne4 12. Bxe7 Qxe7 13. Bxe4 dxe4 14. Nd2',
          why: 'Allowing the exchange on e4 hands White the better endgame.',
        },
      ],
    },
  },
  {
    id: 'slav-defence',
    eco: 'D10',
    side: 'black',
    seed: '1. d4 d5 2. c4 c6',
    mainline: 'Nf3 Nf6 Nc3 dxc4 a4 Bf5 e3 e6 Bxc4 Bb4',
    tags: ['solid', 'positional', 'classical'],
    difficulty: 3,
    popularity: 80,
    de: {
      name: 'Slawische Verteidigung',
      summary:
        'Schwarz stuetzt d5 mit c6 statt e6 und haelt dem Laeufer c8 den Weg frei. '
        + 'Genauso solide wie das abgelehnte Damengambit, aber mit besserem Laeufer.',
      plans: [
        'Den Laeufer c8 nach f5 oder g4 entwickeln, bevor e6 kommt.',
        'Nach dxc4 den Bauern mit b5 halten und die Damenseite ausdehnen.',
        'Mit c6–c5 im richtigen Moment das Zentrum sprengen.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. e3 b5 6. a4 b4 7. Na2 e6 8. Bxc4 Be7 9. O-O O-O 10. Qe2 Bb7 11. Rd1 a5 12. e4',
          why: 'Den Bauern c4 mit b5 zu halten funktioniert nur mit genauer Fortsetzung.',
        },
        {
          line: '1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 Bf5 5. cxd5 cxd5 6. Qb3 Bc8',
          why: 'Der Laeufer auf f5 laesst b7 ungedeckt — hier muss Schwarz ihn beschaemt zuruecknehmen.',
        },
      ],
    },
    en: {
      name: 'Slav Defence',
      summary:
        'Black supports d5 with c6 instead of e6, keeping the c8 bishop’s path clear. '
        + 'Just as solid as the QGD, but with a better bishop.',
      plans: [
        'Develop the c8 bishop to f5 or g4 before playing e6.',
        'After dxc4, hold the pawn with b5 and expand on the queenside.',
        'Break with c6–c5 at the right moment.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. e3 b5 6. a4 b4 7. Na2 e6 8. Bxc4 Be7 9. O-O O-O 10. Qe2 Bb7 11. Rd1 a5 12. e4',
          why: 'Holding c4 with b5 only works with an accurate follow-up.',
        },
        {
          line: '1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 Bf5 5. cxd5 cxd5 6. Qb3 Bc8',
          why: 'The bishop on f5 leaves b7 hanging — here Black has to retreat in shame.',
        },
      ],
    },
  },
  {
    id: 'semi-slav',
    eco: 'D43',
    side: 'black',
    seed: '1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6',
    mainline: 'Bg5 dxc4 e4 b5 e5 h6 Bh4 g5',
    tags: ['tactical', 'attacking', 'theoryHeavy'],
    difficulty: 5,
    popularity: 64,
    de: {
      name: 'Halbslawisch',
      summary:
        'Die Kombination aus Slawisch und Damengambit — und der Einstieg in das Botwinnik-System, '
        + 'eine der schaerfsten Varianten des ganzen Schachs.',
      plans: [
        'Mit dxc4 und b5 den Mehrbauern halten und die Damenseite ausdehnen.',
        'Den Laeufer c8 ueber b7 auf die lange Diagonale bringen.',
        'Mit c6–c5 den Befreiungsschlag vorbereiten.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. Bg5 dxc4 6. e4 b5 7. e5 h6 8. Bh4 g5 9. Nxg5 hxg5 10. Bxg5 Be7 11. exf6 Bxf6 12. g3 Nd7',
          why: 'Im Botwinnik-System sind Bxf6 und Qxf6 nicht dasselbe — hier faellt Schwarz aus der Theorie.',
        },
        {
          line: '1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. e3 Nbd7 6. Bd3 dxc4 7. Bxc4 b5 8. Bd3 a6 9. e4 c5 10. e5 cxd4 11. Nxb5 axb5 12. exf6 gxf6 13. O-O',
          why: 'Das Springeropfer auf b5 ist bekannt — Schwarz muss Qb6 statt axb5 spielen.',
        },
      ],
    },
    en: {
      name: 'Semi-Slav',
      summary:
        'The blend of Slav and QGD — and the gateway to the Botvinnik System, '
        + 'one of the sharpest variations in all of chess.',
      plans: [
        'Hold the extra pawn with dxc4 and b5, expanding on the queenside.',
        'Bring the c8 bishop to the long diagonal via b7.',
        'Prepare the freeing break c6–c5.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. Bg5 dxc4 6. e4 b5 7. e5 h6 8. Bh4 g5 9. Nxg5 hxg5 10. Bxg5 Be7 11. exf6 Bxf6 12. g3 Nd7',
          why: 'In the Botvinnik System Bxf6 and Qxf6 are not the same — Black leaves theory here.',
        },
        {
          line: '1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. e3 Nbd7 6. Bd3 dxc4 7. Bxc4 b5 8. Bd3 a6 9. e4 c5 10. e5 cxd4 11. Nxb5 axb5 12. exf6 gxf6 13. O-O',
          why: 'The knight sacrifice on b5 is well known — Black should play Qb6 instead of axb5.',
        },
      ],
    },
  },
  {
    id: 'gruenfeld-defence',
    eco: 'D80',
    side: 'black',
    seed: '1. d4 Nf6 2. c4 g6 3. Nc3 d5',
    mainline: 'cxd5 Nxd5 e4 Nxc3 bxc3 Bg7 Nf3 c5',
    tags: ['tactical', 'modern', 'open', 'theoryHeavy'],
    difficulty: 5,
    popularity: 68,
    de: {
      name: 'Gruenfeld-Indisch',
      summary:
        'Schwarz laesst Weiss ein Riesenzentrum bauen und schiesst es dann mit c5, Bg7 und Nc6 zusammen. '
        + 'Hypermodernes Schach in Reinform.',
      plans: [
        'Mit c7–c5 die Basis des weissen Zentrums angreifen.',
        'Den Laeufer g7 gegen d4 und c3 arbeiten lassen.',
        'Die Dame nach a5 stellen und den Bauern c3 unter Druck setzen.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Bc4 O-O 8. Ne2 b6',
          why: 'b6 ist zu langsam; c5 muss sofort kommen, sonst festigt Weiss das Zentrum.',
        },
        {
          line: '1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Nf3 Bg7 5. Qb3 dxc4 6. Qxc4 O-O 7. e4 Na6 8. Be2 c5 9. d5 e6 10. O-O exd5 11. exd5 Bf5 12. Rd1 Re8 13. d6',
          why: 'Der Freibauer d6 wird gefaehrlich, wenn Schwarz ihn nicht sofort blockiert.',
        },
      ],
    },
    en: {
      name: 'Grünfeld Defence',
      summary:
        'Black lets White build a huge centre and then shoots it down with c5, Bg7 and Nc6. '
        + 'Hypermodern chess in its purest form.',
      plans: [
        'Attack the base of White’s centre with c7–c5.',
        'Let the g7 bishop work against d4 and c3.',
        'Put the queen on a5 and pressure the c3 pawn.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Bc4 O-O 8. Ne2 b6',
          why: 'b6 is too slow; c5 has to come at once or White consolidates the centre.',
        },
        {
          line: '1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Nf3 Bg7 5. Qb3 dxc4 6. Qxc4 O-O 7. e4 Na6 8. Be2 c5 9. d5 e6 10. O-O exd5 11. exd5 Bf5 12. Rd1 Re8 13. d6',
          why: 'The d6 passed pawn becomes dangerous unless Black blockades it immediately.',
        },
      ],
    },
  },
  {
    id: 'queens-indian',
    eco: 'E12',
    side: 'black',
    seed: '1. d4 Nf6 2. c4 e6 3. Nf3 b6',
    mainline: 'g3 Ba6 b3 Bb4+ Bd2 Be7 Bg2 c6 Bc3 d5',
    tags: ['solid', 'positional', 'flexible'],
    difficulty: 4,
    popularity: 58,
    de: {
      name: 'Damenindische Verteidigung',
      summary:
        'Der Laeufer geht nach b7 und kaempft mit dem Springer f6 um das Feld e4. '
        + 'Sehr solide, oft Uebergang ins Nimzoindische oder Katalanische.',
      plans: [
        'Das Feld e4 mit Bb7, Nf6 und d5 kontrollieren.',
        'Mit Ba6 den Bauern c4 angreifen, bevor Weiss ihn deckt.',
        'Nach d5 die Struktur des Damengambits mit besserem Laeufer erreichen.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Bb7 5. Bg2 Be7 6. O-O O-O 7. Nc3 Ne4 8. Qc2 Nxc3 9. Qxc3 f5 10. b3 Bf6 11. Bb2 d6 12. Rad1 Nd7 13. Ne1 Bxg2 14. Kxg2',
          why: 'Den Laeufer b7 abzutauschen gibt die Figur auf, die um e4 kaempft.',
        },
        {
          line: '1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. a3 Bb7 5. Nc3 d5 6. cxd5 Nxd5 7. e3 Nxc3 8. bxc3 Be7 9. Bb5+ c6 10. Bd3 c5 11. O-O Nc6 12. Bb2',
          why: 'Zweimal mit demselben Springer zu tauschen verschenkt zwei Tempi.',
        },
      ],
    },
    en: {
      name: 'Queen’s Indian Defence',
      summary:
        'The bishop goes to b7 and fights with the f6 knight for the e4 square. '
        + 'Very solid, often transposing to the Nimzo-Indian or Catalan.',
      plans: [
        'Control e4 with Bb7, Nf6 and d5.',
        'Hit the c4 pawn with Ba6 before White defends it.',
        'Reach a QGD structure with a better bishop after d5.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Bb7 5. Bg2 Be7 6. O-O O-O 7. Nc3 Ne4 8. Qc2 Nxc3 9. Qxc3 f5 10. b3 Bf6 11. Bb2 d6 12. Rad1 Nd7 13. Ne1 Bxg2 14. Kxg2',
          why: 'Trading the b7 bishop gives up the piece that fights for e4.',
        },
        {
          line: '1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. a3 Bb7 5. Nc3 d5 6. cxd5 Nxd5 7. e3 Nxc3 8. bxc3 Be7 9. Bb5+ c6 10. Bd3 c5 11. O-O Nc6 12. Bb2',
          why: 'Trading twice with the same knight throws away two tempi.',
        },
      ],
    },
  },
  {
    id: 'dutch-defence',
    eco: 'A80',
    side: 'black',
    seed: '1. d4 f5',
    mainline: 'g3 Nf6 Bg2 e6 Nf3 Be7 O-O O-O c4 d6 Nc3 Qe8',
    tags: ['attacking', 'closed', 'tactical'],
    difficulty: 4,
    popularity: 34,
    de: {
      name: 'Hollaendische Verteidigung',
      summary:
        'Schwarz nimmt sofort Raum am Koenigsfluegel und spielt auf Angriff. '
        + 'Unsymmetrisch und kaempferisch, aber die Diagonale a2–g8 bleibt dauerhaft empfindlich.',
      plans: [
        'Im Leningrader Aufbau mit g6, Bg7 und e5 im Zentrum durchbrechen.',
        'Im Klassischen Aufbau die Dame ueber e8 nach h5 fuehren.',
        'Den Springer nach e4 bringen und dort verankern.',
      ],
      mistakes: [
        {
          line: '1. d4 f5 2. e4 fxe4 3. Nc3 Nf6 4. Bg5 e6',
          why: 'Das Staunton-Gambit anzunehmen und dann passiv zu spielen fuehrt schnell in Schwierigkeiten.',
        },
        {
          line: '1. d4 f5 2. Bg5 h6 3. Bh4 g5 4. e4 Rh7',
          why: 'Die Bauern vor dem eigenen Koenig zu bewegen, bevor er in Sicherheit ist, ist der klassische Hollaender-Fehler.',
        },
      ],
    },
    en: {
      name: 'Dutch Defence',
      summary:
        'Black grabs kingside space at once and plays for attack. '
        + 'Unbalanced and combative, but the a2–g8 diagonal stays permanently sensitive.',
      plans: [
        'In the Leningrad setup, break with g6, Bg7 and e5.',
        'In the Classical setup, lift the queen via e8 to h5.',
        'Post a knight on e4 and anchor it there.',
      ],
      mistakes: [
        {
          line: '1. d4 f5 2. e4 fxe4 3. Nc3 Nf6 4. Bg5 e6',
          why: 'Accepting the Staunton Gambit and then playing passively leads to trouble fast.',
        },
        {
          line: '1. d4 f5 2. Bg5 h6 3. Bh4 g5 4. e4 Rh7',
          why: 'Moving the pawns in front of your own king before it is safe is the classic Dutch mistake.',
        },
      ],
    },
  },
  {
    id: 'benoni-defence',
    eco: 'A60',
    side: 'black',
    seed: '1. d4 Nf6 2. c4 c5 3. d5 e6',
    mainline: 'Nc3 exd5 cxd5 d6 e4 g6 Nf3 Bg7 Be2 O-O',
    tags: ['attacking', 'tactical', 'modern'],
    difficulty: 4,
    popularity: 40,
    de: {
      name: 'Moderne Benoni-Verteidigung',
      summary:
        'Schwarz akzeptiert einen Raumnachteil und einen Rueckstandsbauern, bekommt dafuer die halboffene e-Linie '
        + 'und den Bauernvorstoss b5. Alles oder nichts.',
      plans: [
        'Mit a6 und b5 am Damenfluegel durchbrechen.',
        'Den Laeufer g7 gegen die weisse Bauernkette arbeiten lassen.',
        'Die halboffene e-Linie mit dem Turm besetzen.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 c5 3. d5 e6 4. Nc3 exd5 5. cxd5 d6 6. e4 g6 7. f4 Bg7 8. Bb5+ Nfd7 9. a4 O-O 10. Nf3 Na6 11. O-O Nc7 12. Bxd7',
          why: 'Gegen den Taimanow-Angriff muss Nfd7 kommen; Nbd7 verliert nach e5 sofort.',
        },
        {
          line: '1. d4 Nf6 2. c4 c5 3. d5 e6 4. Nc3 exd5 5. cxd5 d6 6. e4 g6 7. Nf3 Bg7 8. Be2 O-O 9. O-O Re8 10. Nd2 Nbd7 11. a4 Ne5 12. Qc2 g5 13. Nf3',
          why: 'g5 schwaecht den eigenen Koenig, ohne dass der Damenfluegel schon laeuft.',
        },
      ],
    },
    en: {
      name: 'Modern Benoni',
      summary:
        'Black accepts less space and a backward pawn in return for the half-open e-file '
        + 'and the b5 break. All or nothing.',
      plans: [
        'Break on the queenside with a6 and b5.',
        'Let the g7 bishop work against White’s pawn chain.',
        'Occupy the half-open e-file with a rook.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 c5 3. d5 e6 4. Nc3 exd5 5. cxd5 d6 6. e4 g6 7. f4 Bg7 8. Bb5+ Nfd7 9. a4 O-O 10. Nf3 Na6 11. O-O Nc7 12. Bxd7',
          why: 'Against the Taimanov Attack Nfd7 is required; Nbd7 loses at once to e5.',
        },
        {
          line: '1. d4 Nf6 2. c4 c5 3. d5 e6 4. Nc3 exd5 5. cxd5 d6 6. e4 g6 7. Nf3 Bg7 8. Be2 O-O 9. O-O Re8 10. Nd2 Nbd7 11. a4 Ne5 12. Qc2 g5 13. Nf3',
          why: 'g5 weakens your own king while the queenside play has not even started.',
        },
      ],
    },
  },
  {
    id: 'queens-gambit-accepted',
    eco: 'D20',
    side: 'black',
    seed: '1. d4 d5 2. c4 dxc4',
    mainline: 'e4 Nf6 Nc3 e5 Nf3 exd4 Qxd4 Qxd4 Nxd4',
    tags: ['open', 'flexible', 'theoryLight'],
    difficulty: 3,
    popularity: 62,
    de: {
      name: 'Damengambit — Angenommen',
      summary:
        'Schwarz nimmt den Bauern, gibt aber das Zentrum ab und holt ihn spaeter nicht zwingend. '
        + 'Dafuer wird der Laeufer c8 frei und die Stellung oeffnet sich schnell.',
      plans: [
        'Mit c7–c5 oder e7–e5 das Zentrum sofort angreifen.',
        'Den Laeufer c8 nach f5 oder g4 entwickeln.',
        'Nicht am Mehrbauern kleben — Entwicklung geht vor.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. c4 dxc4 3. Nf3 b5 4. a4 c6 5. axb5 cxb5 6. Nc3 a6 7. Nxb5 axb5 8. Rxa8',
          why: 'Der Versuch, den Bauern mit b5 zu halten, endet regelmaessig im Turmverlust auf a8.',
        },
        {
          line: '1. d4 d5 2. c4 dxc4 3. e4 e5 4. Nf3 Bb4+ 5. Nc3 exd4 6. Nxd4 Nf6 7. Bxc4 Nxe4 8. O-O Nxc3 9. bxc3 Bxc3 10. Qb3',
          why: 'Zwei Bauern zu nehmen kostet die Entwicklung und laeuft in den Doppelangriff auf b3.',
        },
      ],
    },
    en: {
      name: 'Queen’s Gambit Accepted',
      summary:
        'Black takes the pawn but concedes the centre and does not necessarily keep the extra pawn. '
        + 'In return the c8 bishop is free and the position opens quickly.',
      plans: [
        'Hit the centre immediately with c7–c5 or e7–e5.',
        'Develop the c8 bishop to f5 or g4.',
        'Do not cling to the extra pawn — development comes first.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. c4 dxc4 3. Nf3 b5 4. a4 c6 5. axb5 cxb5 6. Nc3 a6 7. Nxb5 axb5 8. Rxa8',
          why: 'Trying to hold the pawn with b5 regularly ends with the rook falling on a8.',
        },
        {
          line: '1. d4 d5 2. c4 dxc4 3. e4 e5 4. Nf3 Bb4+ 5. Nc3 exd4 6. Nxd4 Nf6 7. Bxc4 Nxe4 8. O-O Nxc3 9. bxc3 Bxc3 10. Qb3',
          why: 'Grabbing two pawns costs all development and walks into the double attack from b3.',
        },
      ],
    },
  },
  {
    id: 'benko-gambit',
    eco: 'A57',
    side: 'black',
    seed: '1. d4 Nf6 2. c4 c5 3. d5 b5',
    mainline: 'cxb5 a6 bxa6 Bxa6 Nc3 d6 e4 Bxf1 Kxf1 g6',
    tags: ['gambit', 'positional', 'attacking'],
    difficulty: 3,
    popularity: 30,
    de: {
      name: 'Benko-Gambit',
      summary:
        'Ein Bauer fuer dauerhaften Druck auf der a- und b-Linie. '
        + 'Das seltene Gambit, das auch im Endspiel noch Kompensation gibt.',
      plans: [
        'Die Tuerme auf a8 und b8 aufstellen und die offenen Linien besetzen.',
        'Den Laeufer nach g7 fianchettieren und auf d4 druecken.',
        'Den Bauernvorstoss a6–a5–a4 vorbereiten.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 c5 3. d5 b5 4. cxb5 a6 5. b6',
          why: 'Den Bauern zurueckzugeben nimmt Schwarz die Linien — die Ablehnung ist unangenehmer als die Annahme.',
        },
        {
          line: '1. d4 Nf6 2. c4 c5 3. d5 b5 4. cxb5 a6 5. bxa6 Bxa6 6. Nc3 d6 7. e4 Bxf1 8. Kxf1 g6 9. g3 Bg7 10. Kg2 O-O 11. Nf3 Nbd7 12. Re1 Qa5 13. Re2 Rfb8 14. Rb1 Ne8 15. h3 Nc7 16. Bf4 Rb4',
          why: 'Der Turm auf b4 steht ungedeckt; a4 haette den Druck ohne Risiko erhoeht.',
        },
      ],
    },
    en: {
      name: 'Benko Gambit',
      summary:
        'A pawn for lasting pressure on the a- and b-files. '
        + 'The rare gambit whose compensation survives into the endgame.',
      plans: [
        'Line the rooks up on a8 and b8 and take the open files.',
        'Fianchetto to g7 and press on d4.',
        'Prepare the pawn push a6–a5–a4.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 c5 3. d5 b5 4. cxb5 a6 5. b6',
          why: 'Returning the pawn denies Black the files — declining is more annoying than accepting.',
        },
        {
          line: '1. d4 Nf6 2. c4 c5 3. d5 b5 4. cxb5 a6 5. bxa6 Bxa6 6. Nc3 d6 7. e4 Bxf1 8. Kxf1 g6 9. g3 Bg7 10. Kg2 O-O 11. Nf3 Nbd7 12. Re1 Qa5 13. Re2 Rfb8 14. Rb1 Ne8 15. h3 Nc7 16. Bf4 Rb4',
          why: 'The rook on b4 is undefended; a4 would have increased the pressure risk-free.',
        },
      ],
    },
  },
];
