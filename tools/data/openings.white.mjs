// Die Bibliothekseintraege fuer Weiss.
//
// `seed` legt fest, ab wo die Eroeffnung beginnt; der Variantenbaum entsteht
// beim Bauen aus allen benannten ECO-Linien, die darauf aufsetzen.
// `mainline` bestimmt, welcher Ast die Hauptvariante wird.
// `mistakes` sind Linien, deren letzter Zug der Fehler ist.

export const whiteOpenings = [
  // ── 1.e4 gegen 1…e5 ────────────────────────────────────────────────────────
  {
    id: 'italian-game',
    eco: 'C50',
    side: 'white',
    seed: '1. e4 e5 2. Nf3 Nc6 3. Bc4',
    mainline: 'Bc5 c3 Nf6 d3 d6 O-O O-O',
    tags: ['classical', 'positional', 'open', 'beginnerFriendly'],
    difficulty: 2,
    popularity: 88,
    de: {
      name: 'Italienisch',
      summary:
        'Der Laeufer zielt sofort auf f7, dem schwaechsten Punkt in Schwarz’ Stellung. '
        + 'Die moderne Behandlung mit c3 und d3 baut in Ruhe ein Bauernzentrum auf, statt sofort zu stuermen.',
      plans: [
        'Mit c3 und d3 das Zentrum stuetzen und spaeter d3–d4 durchsetzen.',
        'Den Springer ueber b1–d2–f1–g3 an den Koenigsfluegel bringen.',
        'Auf a4 den Laeufer vor Schwarz’ b7–b5 in Sicherheit bringen.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. d4',
          why: 'Zu frueh: nach exd4 verliert Weiss das Zentrum und Schwarz steht bequem.',
        },
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. Ng5 d5 5. exd5 Nxd5',
          why: 'Der Zwei-Springer-Abzug ist eine Falle: 6. Nxf7 Kxf7 kostet Material fuer wenig Angriff.',
        },
      ],
    },
    en: {
      name: 'Italian Game',
      summary:
        'The bishop eyes f7, the weakest point in Black’s camp. '
        + 'The modern treatment with c3 and d3 builds a pawn centre calmly instead of storming immediately.',
      plans: [
        'Support the centre with c3 and d3, then push d3–d4 later.',
        'Reroute the knight via b1–d2–f1–g3 towards the kingside.',
        'Retreat the bishop to a4 before Black plays b7–b5.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. d4',
          why: 'Too early: after exd4 White loses the centre and Black is comfortable.',
        },
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. Ng5 d5 5. exd5 Nxd5',
          why: 'The Two Knights fork trick: 6. Nxf7 Kxf7 gives up material for little attack.',
        },
      ],
    },
  },
  {
    id: 'ruy-lopez',
    eco: 'C60',
    side: 'white',
    seed: '1. e4 e5 2. Nf3 Nc6 3. Bb5',
    mainline: 'a6 Ba4 Nf6 O-O Be7 Re1 b5 Bb3 d6 c3 O-O h3',
    tags: ['classical', 'positional', 'open', 'theoryHeavy'],
    difficulty: 4,
    popularity: 96,
    de: {
      name: 'Spanische Partie',
      summary:
        'Die am gruendlichsten erforschte offene Eroeffnung. Weiss setzt den Springer c6 unter Druck '
        + 'und spielt langfristig auf einen Raumvorteil am Koenigsfluegel.',
      plans: [
        'Den Springer ueber d2–f1–g3 zum Koenigsfluegel manoevrieren.',
        'Mit d2–d4 im richtigen Moment das Zentrum oeffnen.',
        'Den Laeufer b3 auf der Diagonale a2–g8 halten und c2–c3 als Rueckhalt spielen.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Bxc6 dxc6 5. Nxe5',
          why: 'Bauernraub: nach Qd4 gewinnt Schwarz die Figur zurueck und steht besser.',
        },
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. Re1 Nd6 6. Nxe5 Nxe5 7. Rxe5+ Be7 8. Nc3 O-O 9. Nd5 Nf5',
          why: 'Die Berliner Mauer ist zaeh — wer hier auf schnellen Angriff hofft, verrechnet sich.',
        },
      ],
    },
    en: {
      name: 'Ruy Lopez',
      summary:
        'The most thoroughly explored open opening. White pressures the c6 knight '
        + 'and plays for long-term space on the kingside.',
      plans: [
        'Manoeuvre the knight via d2–f1–g3 to the kingside.',
        'Open the centre with d2–d4 at the right moment.',
        'Keep the b3 bishop on the a2–g8 diagonal, backed up by c2–c3.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Bxc6 dxc6 5. Nxe5',
          why: 'Pawn grab: after Qd4 Black regains the piece with the better game.',
        },
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. Re1 Nd6 6. Nxe5 Nxe5 7. Rxe5+ Be7 8. Nc3 O-O 9. Nd5 Nf5',
          why: 'The Berlin Wall is resilient — hoping for a quick attack here is a miscalculation.',
        },
      ],
    },
  },
  {
    id: 'scotch-game',
    eco: 'C45',
    side: 'white',
    seed: '1. e4 e5 2. Nf3 Nc6 3. d4',
    mainline: 'exd4 Nxd4 Bc5 Be3 Qf6 c3 Nge7',
    tags: ['open', 'tactical', 'theoryLight'],
    difficulty: 2,
    popularity: 70,
    de: {
      name: 'Schottische Partie',
      summary:
        'Weiss oeffnet das Zentrum sofort und tauscht den d-Bauern gegen freie Figurenentwicklung. '
        + 'Ein guter Weg, der riesigen Theorie der Spanischen aus dem Weg zu gehen.',
      plans: [
        'Den Springer auf d4 zentral halten und mit c3 und Be3 stuetzen.',
        'Nach Nxc6 bxc6 die schwarzen Doppelbauern zum Ziel machen.',
        'Schnell rochieren und die e-Linie besetzen.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Qh4',
          why: 'Sieht aggressiv aus, kostet Schwarz aber Zeit — Weiss gewinnt mit Nb5 und Be3 Tempo.',
        },
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Bc4 Bc5 5. Ng5',
          why: 'Der Springerangriff auf f7 verpufft; Schwarz spielt Ne5 und steht ausgezeichnet.',
        },
      ],
    },
    en: {
      name: 'Scotch Game',
      summary:
        'White opens the centre at once, trading the d-pawn for free piece play. '
        + 'A practical way to sidestep the huge body of Ruy Lopez theory.',
      plans: [
        'Keep the knight centralised on d4, supported by c3 and Be3.',
        'After Nxc6 bxc6, target Black’s doubled pawns.',
        'Castle quickly and occupy the e-file.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Qh4',
          why: 'Looks aggressive but loses time — White gains tempi with Nb5 and Be3.',
        },
        {
          line: '1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Bc4 Bc5 5. Ng5',
          why: 'The knight sortie against f7 fizzles out; Black plays Ne5 with an excellent game.',
        },
      ],
    },
  },
  {
    id: 'vienna-game',
    eco: 'C25',
    side: 'white',
    seed: '1. e4 e5 2. Nc3',
    mainline: 'Nf6 f4 d5 fxe5 Nxe4',
    tags: ['attacking', 'tactical', 'open', 'theoryLight'],
    difficulty: 3,
    popularity: 52,
    de: {
      name: 'Wiener Partie',
      summary:
        'Ein Koenigsgambit mit Verspaetung: erst wird Nc3 entwickelt, dann kommt f2–f4. '
        + 'Schwarz muss genau spielen, sonst wird die f-Linie schnell gefaehrlich.',
      plans: [
        'Mit f2–f4 die f-Linie oeffnen und den Turm dort einsetzen.',
        'Den Laeufer nach c4 stellen und auf f7 zielen.',
        'Bei ruhigem Aufbau mit g3 und Bg2 auf d5 druecken.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nc3 Nf6 3. f4 exf4 4. e5 Ng8',
          why: 'Der Rueckzug nach g8 gibt alle Entwicklung auf; Qe7 ist die Widerlegung.',
        },
        {
          line: '1. e4 e5 2. Nc3 Nc6 3. Bc4 Nf6 4. d3 Bc5 5. Bg5 h6 6. Bxf6 Qxf6 7. Nd5 Qd8',
          why: 'Der Rueckzug der Dame nach d8 macht alles Vorherige rueckgaengig — Qd6 haelt die Stellung zusammen.',
        },
      ],
    },
    en: {
      name: 'Vienna Game',
      summary:
        'A King’s Gambit with a delay: develop Nc3 first, then push f2–f4. '
        + 'Black has to be accurate or the f-file becomes dangerous quickly.',
      plans: [
        'Open the f-file with f2–f4 and put a rook on it.',
        'Post the bishop on c4 and aim at f7.',
        'In quieter lines, fianchetto with g3 and Bg2 to pressure d5.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. Nc3 Nf6 3. f4 exf4 4. e5 Ng8',
          why: 'Retreating to g8 undoes all development; Qe7 is the refutation.',
        },
        {
          line: '1. e4 e5 2. Nc3 Nc6 3. Bc4 Nf6 4. d3 Bc5 5. Bg5 h6 6. Bxf6 Qxf6 7. Nd5 Qd8',
          why: 'Retreating the queen to d8 undoes everything — Qd6 keeps the position together.',
        },
      ],
    },
  },
  {
    id: 'kings-gambit',
    eco: 'C30',
    side: 'white',
    seed: '1. e4 e5 2. f4',
    mainline: 'exf4 Nf3 g5 h4 g4 Ne5',
    tags: ['gambit', 'attacking', 'tactical', 'open'],
    difficulty: 4,
    popularity: 34,
    de: {
      name: 'Koenigsgambit',
      summary:
        'Weiss gibt einen Bauern fuer das Zentrum und die offene f-Linie. '
        + 'Romantisches Schach: wer beide Seiten kennt, gewinnt hier viele Blitzpartien.',
      plans: [
        'Mit d4 das Zentrum besetzen, waehrend Schwarz den Mehrbauern verteidigt.',
        'Den Turm ueber f1 auf die halboffene f-Linie bringen.',
        'Den Bauern f4 spaeter mit Bxf4 oder g3 zurueckholen.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. f4 exf4 3. Nf3 g5 4. Bc4 g4 5. O-O',
          why: 'Das Muzio-Gambit opfert eine ganze Figur — spektakulaer, aber objektiv nicht ausreichend.',
        },
        {
          line: '1. e4 e5 2. f4 exf4 3. Nf3 d6 4. Bc4 h6 5. d4 g5 6. h4 Bg7 7. c3 Nc6 8. O-O Qe7 9. g3',
          why: 'Die Linie zu frueh aufzureissen kostet den Koenig die Deckung.',
        },
      ],
    },
    en: {
      name: 'King’s Gambit',
      summary:
        'White gives a pawn for the centre and the open f-file. '
        + 'Romantic chess: knowing both sides wins a lot of blitz games.',
      plans: [
        'Occupy the centre with d4 while Black defends the extra pawn.',
        'Bring the rook to the half-open f-file.',
        'Recapture on f4 later with Bxf4 or g3.',
      ],
      mistakes: [
        {
          line: '1. e4 e5 2. f4 exf4 3. Nf3 g5 4. Bc4 g4 5. O-O',
          why: 'The Muzio Gambit sacrifices a whole piece — spectacular but objectively insufficient.',
        },
        {
          line: '1. e4 e5 2. f4 exf4 3. Nf3 d6 4. Bc4 h6 5. d4 g5 6. h4 Bg7 7. c3 Nc6 8. O-O Qe7 9. g3',
          why: 'Opening the file too early costs the king its cover.',
        },
      ],
    },
  },

  // ── 1.e4 gegen Sizilianisch ────────────────────────────────────────────────
  {
    id: 'open-sicilian',
    eco: 'B50',
    side: 'white',
    seed: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3',
    mainline: 'a6 Be3 e5 Nb3 Be6 f3 Be7',
    tags: ['open', 'tactical', 'attacking', 'theoryHeavy'],
    difficulty: 5,
    popularity: 92,
    de: {
      name: 'Sizilianisch — Offene Variante',
      summary:
        'Der Hauptweg gegen Sizilianisch: Weiss tauscht auf d4 und spielt auf Entwicklungsvorsprung. '
        + 'Dafuer muss man Najdorf, Drachen und Scheveningen im Griff haben.',
      plans: [
        'Lange rochieren und mit f3, g4, h4 am Koenigsfluegel stuermen.',
        'Den Springer d4 gut platzieren — nach b3 oder f3 statt ihn abtauschen zu lassen.',
        'Die halboffene d-Linie fuer den Turm nutzen.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 Qb6 8. Qd2 Qxb2',
          why: 'Der vergiftete Bauer: wer ihn ohne genaue Kenntnis nimmt oder gibt, steht schnell verloren.',
        },
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Qxd4',
          why: 'Die Dame zu frueh ins Zentrum: Nc6 gewinnt mit Tempo die Initiative.',
        },
      ],
    },
    en: {
      name: 'Sicilian — Open Variation',
      summary:
        'The main road against the Sicilian: White trades on d4 and plays for a development lead. '
        + 'It demands a working knowledge of the Najdorf, Dragon and Scheveningen.',
      plans: [
        'Castle long and storm the kingside with f3, g4 and h4.',
        'Place the d4 knight well — on b3 or f3 rather than letting it be traded.',
        'Use the half-open d-file for a rook.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 Qb6 8. Qd2 Qxb2',
          why: 'The poisoned pawn: taking or offering it without precise knowledge loses quickly.',
        },
        {
          line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Qxd4',
          why: 'Bringing the queen out too early: Nc6 gains the initiative with tempo.',
        },
      ],
    },
  },
  {
    id: 'alapin-sicilian',
    eco: 'B22',
    side: 'white',
    seed: '1. e4 c5 2. c3',
    mainline: 'Nf6 e5 Nd5 d4 cxd4 Nf3 Nc6 cxd4 d6',
    tags: ['positional', 'solid', 'theoryLight', 'beginnerFriendly'],
    difficulty: 2,
    popularity: 66,
    de: {
      name: 'Sizilianisch — Alapin',
      summary:
        'Weiss bereitet d2–d4 vor und baut ein grosses Bauernzentrum, statt sich auf die Theorieschlacht einzulassen. '
        + 'Der praktischste Weg gegen Sizilianisch fuer alle, die wenig Zeit zum Lernen haben.',
      plans: [
        'Mit d4 ein Bauernzentrum bilden und es mit c3 halten.',
        'Nach e5 den Springer nach d5 locken und ihn dort mit Tempo vertreiben.',
        'Auf dem isolierten Damenbauern aktiv spielen, statt ihn zu bedauern.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. c3 d5 3. exd5 Qxd5 4. d4 Nf6 5. Nf3 Bg4 6. Be2 e6 7. h3 Bh5 8. O-O Nc6 9. Be3 cxd4 10. cxd4 Be7 11. Nc3 Qd6 12. a3 O-O 13. Nb5',
          why: 'Der Springerausfall nach b5 verliert Zeit, solange die Dame nicht wirklich gestoert wird.',
        },
        {
          line: '1. e4 c5 2. c3 Nf6 3. e5 Nd5 4. Nf3 Nc6 5. Bc4 Nb6 6. Bb3 c4',
          why: 'Weiss darf hier nicht Bc2 spielen; der Laeufer gehoert nach c2 erst nach d3.',
        },
      ],
    },
    en: {
      name: 'Sicilian — Alapin',
      summary:
        'White prepares d2–d4 and builds a big pawn centre instead of entering a theory battle. '
        + 'The most practical anti-Sicilian for anyone short on study time.',
      plans: [
        'Build a pawn centre with d4 and hold it with c3.',
        'Lure the knight to d5 with e5, then chase it with tempo.',
        'Play actively with the isolated queen’s pawn rather than regretting it.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. c3 d5 3. exd5 Qxd5 4. d4 Nf6 5. Nf3 Bg4 6. Be2 e6 7. h3 Bh5 8. O-O Nc6 9. Be3 cxd4 10. cxd4 Be7 11. Nc3 Qd6 12. a3 O-O 13. Nb5',
          why: 'The knight sortie to b5 loses time while the queen is not genuinely disturbed.',
        },
        {
          line: '1. e4 c5 2. c3 Nf6 3. e5 Nd5 4. Nf3 Nc6 5. Bc4 Nb6 6. Bb3 c4',
          why: 'White must not shuffle the bishop aimlessly here; it belongs on c2 only after d3.',
        },
      ],
    },
  },
  {
    id: 'rossolimo',
    eco: 'B31',
    side: 'white',
    seed: '1. e4 c5 2. Nf3 Nc6 3. Bb5',
    mainline: 'g6 Bxc6 dxc6 d3 Bg7 h3 Nf6 Nc3 O-O',
    tags: ['positional', 'solid', 'theoryLight'],
    difficulty: 3,
    popularity: 74,
    de: {
      name: 'Sizilianisch — Rossolimo',
      summary:
        'Weiss tauscht den Laeufer gegen den Springer c6 und spielt auf die Bauernstruktur. '
        + 'Wenig Theorie, klare Plaene — auf Grossmeisterebene sehr beliebt.',
      plans: [
        'Nach Bxc6 dxc6 die Stellung geschlossen halten und auf den besseren Bauern spielen.',
        'Mit e5 Raum gewinnen und die Diagonale des schwarzen Laeufers stumpf machen.',
        'Die Springer nach e3 und d5 manoevrieren.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. Bb5 g6 4. Bxc6 bxc6',
          why: 'Mit dem b-Bauern zurueckzuschlagen gibt Weiss ein klares Ziel auf der halboffenen b-Linie.',
        },
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. Bb5 e6 4. O-O Nge7 5. c3 a6 6. Ba4 b5 7. Bc2 Bb7 8. Re1 d5',
          why: 'Weiss darf das Zentrum nicht kampflos aufgeben — e5 haelt den Raum.',
        },
      ],
    },
    en: {
      name: 'Sicilian — Rossolimo',
      summary:
        'White trades the bishop for the c6 knight and plays on the pawn structure. '
        + 'Little theory, clear plans — very popular at grandmaster level.',
      plans: [
        'After Bxc6 dxc6, keep the position closed and play on the better pawns.',
        'Gain space with e5 and blunt Black’s bishop.',
        'Manoeuvre the knights to e3 and d5.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. Bb5 g6 4. Bxc6 bxc6',
          why: 'Recapturing with the b-pawn hands White a clear target on the half-open b-file.',
        },
        {
          line: '1. e4 c5 2. Nf3 Nc6 3. Bb5 e6 4. O-O Nge7 5. c3 a6 6. Ba4 b5 7. Bc2 Bb7 8. Re1 d5',
          why: 'White must not surrender the centre without a fight — e5 keeps the space.',
        },
      ],
    },
  },
  {
    id: 'grand-prix-attack',
    eco: 'B23',
    side: 'white',
    seed: '1. e4 c5 2. Nc3 Nc6 3. f4',
    mainline: 'g6 Nf3 Bg7 Bc4 e6 f5',
    extraLines: {
      'g6 Nf3 Bg7 Bb5 Nd4 O-O a6 Bd3': 'Gegen Sd4 den Laeufer halten',
      'e6 Nf3 d5 Bb5 Nge7 O-O a6': 'Franzoesischer Aufbau',
      'd6 Nf3 g6 Bb5 Bd7 O-O Bg7 d3': 'Klassischer Grand-Prix-Aufbau',
      'g6 Nf3 Bg7 Bc4 e6 d3 Nge7 O-O': 'Ruhige Behandlung mit d3',
      'a6 Nf3 b5 d4 cxd4 Nxd4': 'Vorzeitige Damenfluegel-Expansion',
    },
    tags: ['attacking', 'tactical', 'theoryLight'],
    difficulty: 2,
    popularity: 44,
    de: {
      name: 'Sizilianisch — Grand-Prix-Angriff',
      summary:
        'Direkter Angriff mit f4 und Bc4 ohne d4-Abtausch. '
        + 'Im Schnellschach gefaehrlich, weil Schwarz sofort konkret verteidigen muss.',
      plans: [
        'Mit f4–f5 die Diagonale zum Koenigsfluegel oeffnen.',
        'Die Dame nach e1–h4 bringen.',
        'Den Laeufer auf c4 oder b5 aktiv einsetzen, bevor Schwarz d5 schafft.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nc3 Nc6 3. f4 g6 4. Nf3 Bg7 5. Bb5 Nd4 6. Bc4 e6 7. f5 Nxf5',
          why: 'Das Bauernopfer auf f5 funktioniert hier nicht — Weiss steht nach exf5 einfach schlechter.',
        },
        {
          line: '1. e4 c5 2. f4',
          why: 'Ohne Nc3 zuerst schlaegt d5 sofort zurueck und Weiss verliert das Zentrum.',
        },
      ],
    },
    en: {
      name: 'Sicilian — Grand Prix Attack',
      summary:
        'A direct attack with f4 and Bc4 without trading on d4. '
        + 'Dangerous in rapid play because Black has to defend concretely at once.',
      plans: [
        'Open the diagonal towards the kingside with f4–f5.',
        'Swing the queen to e1 and on to h4.',
        'Activate the bishop on c4 or b5 before Black gets in d5.',
      ],
      mistakes: [
        {
          line: '1. e4 c5 2. Nc3 Nc6 3. f4 g6 4. Nf3 Bg7 5. Bb5 Nd4 6. Bc4 e6 7. f5 Nxf5',
          why: 'The f5 pawn sacrifice does not work here — after exf5 White is simply worse.',
        },
        {
          line: '1. e4 c5 2. f4',
          why: 'Without Nc3 first, d5 hits back immediately and White loses the centre.',
        },
      ],
    },
  },

  // ── 1.e4 gegen Franzoesisch und Caro-Kann ─────────────────────────────────
  {
    id: 'french-advance',
    eco: 'C02',
    side: 'white',
    seed: '1. e4 e6 2. d4 d5 3. e5',
    mainline: 'c5 c3 Nc6 Nf3 Qb6 a3 Nh6 b4',
    tags: ['closed', 'positional', 'theoryLight'],
    difficulty: 3,
    popularity: 62,
    de: {
      name: 'Franzoesisch — Vorstossvariante',
      summary:
        'Weiss schliesst das Zentrum und gewinnt Raum. '
        + 'Der schwarze Laeufer c8 bleibt in der eigenen Bauernkette eingesperrt — daran arbeitet man die ganze Partie.',
      plans: [
        'Die Kette d4–e5 mit c3 und f4 halten.',
        'Am Koenigsfluegel mit f4–f5 durchbrechen.',
        'Den Springer ueber f3–h4 nach f5 oder g6 bringen.',
      ],
      mistakes: [
        {
          line: '1. e4 e6 2. d4 d5 3. e5 c5 4. dxc5',
          why: 'Der Abtausch gibt das Zentrum auf und Schwarz holt den Bauern mit Bxc5 bequem zurueck.',
        },
        {
          line: '1. e4 e6 2. d4 d5 3. e5 c5 4. Nf3 Qb6 5. Bd3',
          why: 'Ohne c3 haengt d4: nach cxd4 verliert Weiss das Zentrum.',
        },
      ],
    },
    en: {
      name: 'French — Advance Variation',
      summary:
        'White closes the centre and gains space. '
        + 'Black’s light-squared bishop stays locked behind its own pawns — that is the theme of the whole game.',
      plans: [
        'Hold the d4–e5 chain with c3 and f4.',
        'Break through on the kingside with f4–f5.',
        'Route the knight via f3–h4 to f5 or g6.',
      ],
      mistakes: [
        {
          line: '1. e4 e6 2. d4 d5 3. e5 c5 4. dxc5',
          why: 'The exchange surrenders the centre and Black regains the pawn comfortably with Bxc5.',
        },
        {
          line: '1. e4 e6 2. d4 d5 3. e5 c5 4. Nf3 Qb6 5. Bd3',
          why: 'Without c3 the d4 pawn hangs: after cxd4 White loses the centre.',
        },
      ],
    },
  },
  {
    id: 'french-tarrasch',
    eco: 'C03',
    side: 'white',
    seed: '1. e4 e6 2. d4 d5 3. Nd2',
    mainline: 'Nf6 e5 Nfd7 Bd3 c5 c3 Nc6 Ne2',
    tags: ['positional', 'solid', 'flexible'],
    difficulty: 3,
    popularity: 58,
    de: {
      name: 'Franzoesisch — Tarrasch',
      summary:
        'Der Springer geht nach d2 statt c3 und vermeidet die Fesselung durch Bb4. '
        + 'Weiss behaelt die Struktur flexibel und spielt auf einen kleinen, dauerhaften Vorteil.',
      plans: [
        'Nach e5 den Raumvorteil mit c3 und f4 festigen.',
        'Bei Abtausch auf d5 mit dem isolierten Damenbauern aktiv spielen.',
        'Den Springer d2 ueber f1 nach g3 oder e3 entwickeln.',
      ],
      mistakes: [
        {
          line: '1. e4 e6 2. d4 d5 3. Nd2 c5 4. exd5 Qxd5 5. Ngf3 cxd4 6. Bc4 Qd6 7. O-O Nf6 8. Nb3 Nc6 9. Nbxd4 Nxd4 10. Nxd4 a6 11. Re1 Qc7 12. Bb3 Bd6 13. Nf5',
          why: 'Der Springerausfall nach f5 ist verfrueht, solange die Grundreihe nicht gedeckt ist.',
        },
        {
          line: '1. e4 e6 2. d4 d5 3. Nd2 Nf6 4. e5 Nfd7 5. f4 c5 6. c3 Nc6 7. Ndf3 Qb6 8. g3 cxd4 9. cxd4 Bb4+',
          why: 'Das Schach auf b4 kommt mit Tempo — Weiss haette Bd2 vorbereiten muessen.',
        },
      ],
    },
    en: {
      name: 'French — Tarrasch',
      summary:
        'The knight goes to d2 instead of c3, avoiding the pin with Bb4. '
        + 'White keeps the structure flexible and plays for a small, lasting edge.',
      plans: [
        'After e5, consolidate the space advantage with c3 and f4.',
        'If pawns are traded on d5, play actively with the isolated queen’s pawn.',
        'Develop the d2 knight via f1 to g3 or e3.',
      ],
      mistakes: [
        {
          line: '1. e4 e6 2. d4 d5 3. Nd2 c5 4. exd5 Qxd5 5. Ngf3 cxd4 6. Bc4 Qd6 7. O-O Nf6 8. Nb3 Nc6 9. Nbxd4 Nxd4 10. Nxd4 a6 11. Re1 Qc7 12. Bb3 Bd6 13. Nf5',
          why: 'The knight jump to f5 is premature while the back rank is loose.',
        },
        {
          line: '1. e4 e6 2. d4 d5 3. Nd2 Nf6 4. e5 Nfd7 5. f4 c5 6. c3 Nc6 7. Ndf3 Qb6 8. g3 cxd4 9. cxd4 Bb4+',
          why: 'The check on b4 comes with tempo — White should have prepared Bd2.',
        },
      ],
    },
  },
  {
    id: 'caro-kann-advance',
    eco: 'B12',
    side: 'white',
    seed: '1. e4 c6 2. d4 d5 3. e5',
    mainline: 'Bf5 Nf3 e6 Be2 c5 Be3 Nd7 O-O Ne7',
    extraLines: {
      'Bf5 Nc3 e6 g4 Bg6 Nge2 c5 h4 h5 Nf4': 'Scharfe Behandlung mit g4',
      'Bf5 h4 h5 c4 e6 Nc3 Ne7 Nge2': 'Sofortiger Bauernsturm mit h4',
      'c5 dxc5 e6 Be3 Nd7 Nf3 Ne7 c4': 'Den Mehrbauern halten',
      'Bf5 Nf3 e6 Be2 Ne7 O-O Nd7 Nbd2 h6 Nb3': 'Ruhiger Aufbau mit Sb3',
    },
    tags: ['positional', 'closed', 'flexible'],
    difficulty: 3,
    popularity: 68,
    de: {
      name: 'Caro-Kann — Vorstossvariante',
      summary:
        'Weiss nimmt Raum und laesst Schwarz den Laeufer nach f5 entwickeln — den Laeufer, den der Franzose vermisst. '
        + 'Dafuer geraet er dort ins Visier von Nh4 und g4.',
      plans: [
        'Den Laeufer f5 mit Nh4 oder g4 abtauschen oder vertreiben.',
        'Die Bauernkette d4–e5 mit c3 halten.',
        'Am Koenigsfluegel mit h4–h5 Raum gewinnen.',
      ],
      mistakes: [
        {
          line: '1. e4 c6 2. d4 d5 3. e5 Bf5 4. Bd3',
          why: 'Der Abtausch hilft Schwarz: nach Bxd3 Qxd3 hat er sein Hauptproblem geloest.',
        },
        {
          line: '1. e4 c6 2. d4 d5 3. e5 c5 4. dxc5 e6 5. Be3 Nd7 6. Nf3 Ne7 7. c4 Nc6 8. cxd5 exd5 9. Nc3 Bxc5',
          why: 'Den c5-Bauern zu halten kostet mehr Zeit, als er wert ist.',
        },
      ],
    },
    en: {
      name: 'Caro-Kann — Advance Variation',
      summary:
        'White takes space and lets Black develop the bishop to f5 — the bishop the French player misses. '
        + 'In return it becomes a target for Nh4 and g4.',
      plans: [
        'Trade or chase the f5 bishop with Nh4 or g4.',
        'Hold the d4–e5 pawn chain with c3.',
        'Gain kingside space with h4–h5.',
      ],
      mistakes: [
        {
          line: '1. e4 c6 2. d4 d5 3. e5 Bf5 4. Bd3',
          why: 'The trade helps Black: after Bxd3 Qxd3 his main problem is solved.',
        },
        {
          line: '1. e4 c6 2. d4 d5 3. e5 c5 4. dxc5 e6 5. Be3 Nd7 6. Nf3 Ne7 7. c4 Nc6 8. cxd5 exd5 9. Nc3 Bxc5',
          why: 'Hanging on to the c5 pawn costs more time than it is worth.',
        },
      ],
    },
  },
  {
    id: 'caro-kann-two-knights',
    eco: 'B11',
    side: 'white',
    seed: '1. e4 c6 2. Nc3 d5 3. Nf3',
    mainline: 'Bg4 h3 Bxf3 Qxf3 e6 d3 Nf6 g3',
    extraLines: {
      'dxe4 Nxe4 Bf5 Ng3 Bg6 h4 h6 h5 Bh7 d4': 'Hauptvariante nach dem Abtausch',
      'dxe4 Nxe4 Nd7 d4 Ngf6 Nxf6+ Nxf6 Bd3': 'Karpow-Aufbau',
      'Nf6 e5 Ne4 Ne2 Qb6 d4': 'Sofortiger Vorstoss',
      'Bg4 h3 Bh5 exd5 cxd5 Bb5+ Nc6 g4 Bg6 Ne5': 'Scharfe Behandlung mit g4',
      'e6 d4 dxe4 Nxe4 Nd7 Bd3': 'Uebergang ins Franzoesische',
    },
    tags: ['theoryLight', 'flexible', 'positional'],
    difficulty: 2,
    popularity: 40,
    de: {
      name: 'Caro-Kann — Zwei Springer',
      summary:
        'Weiss entwickelt beide Springer und laesst das Zentrum zunaechst offen. '
        + 'Ein bequemer Weg um die grosse Caro-Kann-Theorie herum.',
      plans: [
        'Mit h3 den Laeufer zur Entscheidung zwingen.',
        'Nach Qxf3 das Laeuferpaar behalten und langsam Raum gewinnen.',
        'Mit d4 im richtigen Moment ins Zentrum vorstossen.',
      ],
      mistakes: [
        {
          line: '1. e4 c6 2. Nc3 d5 3. Nf3 dxe4 4. Nxe4 Nf6 5. Nxf6+ gxf6',
          why: 'Der Abtausch auf f6 gibt Schwarz die offene g-Linie und ein starkes Zentrum.',
        },
        {
          line: '1. e4 c6 2. Nc3 d5 3. Nf3 Bg4 4. h3 Bh5 5. exd5 cxd5 6. Bb5+ Nc6 7. g4 Bg6 8. Ne5 Rc8 9. d4 e6 10. Qe2 f6',
          why: 'Der Springer e5 steht nur so lange gut, wie f6 nicht kommt.',
        },
      ],
    },
    en: {
      name: 'Caro-Kann — Two Knights',
      summary:
        'White develops both knights and keeps the centre open for now. '
        + 'A comfortable way around the large body of Caro-Kann theory.',
      plans: [
        'Force the bishop to commit with h3.',
        'After Qxf3, keep the bishop pair and gain space slowly.',
        'Push d4 into the centre at the right moment.',
      ],
      mistakes: [
        {
          line: '1. e4 c6 2. Nc3 d5 3. Nf3 dxe4 4. Nxe4 Nf6 5. Nxf6+ gxf6',
          why: 'The exchange on f6 hands Black the open g-file and a strong centre.',
        },
        {
          line: '1. e4 c6 2. Nc3 d5 3. Nf3 Bg4 4. h3 Bh5 5. exd5 cxd5 6. Bb5+ Nc6 7. g4 Bg6 8. Ne5 Rc8 9. d4 e6 10. Qe2 f6',
          why: 'The e5 knight is only well placed until f6 arrives.',
        },
      ],
    },
  },
  {
    id: 'austrian-attack',
    eco: 'B09',
    side: 'white',
    seed: '1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. f4',
    mainline: 'Bg7 Nf3 O-O Bd3 Nc6 O-O Bg4 Be3',
    extraLines: {
      'Bg7 Nf3 c5 Bb5+ Bd7 e5 Ng4 Bxd7+ Qxd7 d5': 'Hauptvariante mit c5',
      'Bg7 Nf3 O-O Bd3 Na6 O-O c5 d5': 'Sa6 mit Druck auf c5 und b4',
      'Bg7 e5 dxe5 fxe5 Nd5 Nxd5 Qxd5 Nf3': 'Frueher Vorstoss e5',
      'c5 dxc5 Qa5 Bd3 Qxc5 Qe2 Bg7 Be3 O-O': 'Sofortiges c5',
      'Bg7 Nf3 O-O e5 dxe5 fxe5 Nd5 Bc4 Nb6 Bb3': 'Vorstoss nach der Rochade',
    },
    tags: ['attacking', 'open', 'tactical'],
    difficulty: 3,
    popularity: 38,
    de: {
      name: 'Pirc — Oesterreichischer Angriff',
      summary:
        'Die schaerfste Antwort auf Pirc: Weiss baut ein Bauerndreieck e4–d4–f4 und stuermt. '
        + 'Schwarz muss schnell im Zentrum gegenschlagen, sonst wird er ueberrollt.',
      plans: [
        'Mit e5 das Zentrum aufreissen, sobald Schwarz rochiert hat.',
        'Die Dame nach e1 und weiter nach h4 fuehren.',
        'Den Laeufer nach d3 stellen und auf h7 zielen.',
      ],
      mistakes: [
        {
          line: '1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. f4 Bg7 5. e5 dxe5 6. fxe5 Nfd7 7. e6',
          why: 'Der Bauernvorstoss nach e6 gibt Material ohne ausreichenden Angriff.',
        },
        {
          line: '1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. f4 Bg7 5. Nf3 c5 6. dxc5 Qa5 7. Bd3 Qxc5 8. Qe2 O-O 9. Be3 Qa5 10. O-O Bg4 11. h3 Bxf3 12. Qxf3 Nc6 13. e5',
          why: 'Der Durchbruch e5 muss vorbereitet sein — hier verliert er einen Bauern.',
        },
      ],
    },
    en: {
      name: 'Pirc — Austrian Attack',
      summary:
        'The sharpest answer to the Pirc: White builds the e4–d4–f4 pawn triangle and storms. '
        + 'Black must strike back in the centre quickly or be overrun.',
      plans: [
        'Rip open the centre with e5 once Black has castled.',
        'Lift the queen to e1 and on to h4.',
        'Place the bishop on d3 and aim at h7.',
      ],
      mistakes: [
        {
          line: '1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. f4 Bg7 5. e5 dxe5 6. fxe5 Nfd7 7. e6',
          why: 'The e6 push gives away material without enough attack.',
        },
        {
          line: '1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. f4 Bg7 5. Nf3 c5 6. dxc5 Qa5 7. Bd3 Qxc5 8. Qe2 O-O 9. Be3 Qa5 10. O-O Bg4 11. h3 Bxf3 12. Qxf3 Nc6 13. e5',
          why: 'The e5 break has to be prepared — here it just drops a pawn.',
        },
      ],
    },
  },
  {
    id: 'scandinavian-white',
    eco: 'B01',
    side: 'white',
    seed: '1. e4 d5 2. exd5',
    mainline: 'Qxd5 Nc3 Qa5 d4 Nf6 Nf3 c6 Bc4 Bf5',
    tags: ['open', 'theoryLight', 'beginnerFriendly'],
    difficulty: 2,
    popularity: 36,
    de: {
      name: 'Skandinavisch (aus Weiss’ Sicht)',
      summary:
        'Schwarz holt den Bauern mit der Dame zurueck und verliert dabei Zeit. '
        + 'Weiss entwickelt mit Tempo und steht nach wenigen Zuegen bequem.',
      plans: [
        'Mit Nc3 die Dame angreifen und dabei entwickeln.',
        'Mit d4 und Nf3 das Zentrum besetzen.',
        'Den Laeufer nach d2 stellen, um die Dame auf a5 zu stoeren.',
      ],
      mistakes: [
        {
          line: '1. e4 d5 2. exd5 Qxd5 3. Nf3',
          why: 'Nc3 ist der Punkt der ganzen Variante — ohne den Angriff auf die Dame verliert Weiss seinen Vorteil.',
        },
        {
          line: '1. e4 d5 2. exd5 Nf6 3. c4 c6 4. dxc6 Nxc6',
          why: 'Das Gambit anzunehmen kostet die gesamte Entwicklung; 3. d4 ist der sichere Weg.',
        },
      ],
    },
    en: {
      name: 'Scandinavian (White’s side)',
      summary:
        'Black recaptures with the queen and loses time doing so. '
        + 'White develops with tempo and is comfortable within a few moves.',
      plans: [
        'Attack the queen with Nc3 while developing.',
        'Occupy the centre with d4 and Nf3.',
        'Put the bishop on d2 to harass the queen on a5.',
      ],
      mistakes: [
        {
          line: '1. e4 d5 2. exd5 Qxd5 3. Nf3',
          why: 'Nc3 is the whole point — without hitting the queen White gives up the edge.',
        },
        {
          line: '1. e4 d5 2. exd5 Nf6 3. c4 c6 4. dxc6 Nxc6',
          why: 'Accepting the gambit costs all development; 3. d4 is the safe route.',
        },
      ],
    },
  },
  {
    id: 'alekhine-white',
    eco: 'B03',
    side: 'white',
    seed: '1. e4 Nf6 2. e5 Nd5 3. d4 d6 4. c4',
    mainline: 'Nb6 exd6 exd6 Nc3 Be7 Bd3',
    tags: ['open', 'positional', 'theoryLight'],
    difficulty: 3,
    popularity: 26,
    de: {
      name: 'Aljechin-Verteidigung (aus Weiss’ Sicht)',
      summary:
        'Schwarz laedt die weissen Bauern ein, vorzuruecken, um sie spaeter anzugreifen. '
        + 'Weiss nimmt den Raum — muss ihn dann aber auch halten koennen.',
      plans: [
        'Mit c4 und d4 die Bauern breit aufstellen und den Springer zurueckdraengen.',
        'Die Entwicklung nicht vergessen: Nc3, Nf3, Be2 und rochieren.',
        'Erst dann mit f4 oder d5 den Raumvorteil in Angriff verwandeln.',
      ],
      mistakes: [
        {
          line: '1. e4 Nf6 2. e5 Nd5 3. c4 Nb6 4. c5 Nd5 5. Bc4 e6 6. Nc3 d6 7. Nxd5 exd5 8. Bxd5 Qh4',
          why: 'Der Vier-Bauern-Angriff wird schnell ueberzogen; die Bauern werden zur Schwaeche.',
        },
        {
          line: '1. e4 Nf6 2. Nc3 d5 3. e5 d4 4. exf6 dxc3 5. fxg7 cxd2+ 6. Bxd2 Bxg7',
          why: 'Die Abtauschorgie fuehrt zu einer gleichen Stellung ohne jeden Vorteil.',
        },
      ],
    },
    en: {
      name: 'Alekhine Defence (White’s side)',
      summary:
        'Black invites White’s pawns forward in order to attack them later. '
        + 'White takes the space — but then has to be able to hold it.',
      plans: [
        'Set up broadly with c4 and d4 and push the knight back.',
        'Do not forget development: Nc3, Nf3, Be2 and castle.',
        'Only then convert the space into an attack with f4 or d5.',
      ],
      mistakes: [
        {
          line: '1. e4 Nf6 2. e5 Nd5 3. c4 Nb6 4. c5 Nd5 5. Bc4 e6 6. Nc3 d6 7. Nxd5 exd5 8. Bxd5 Qh4',
          why: 'The Four Pawns Attack overextends quickly; the pawns become weaknesses.',
        },
        {
          line: '1. e4 Nf6 2. Nc3 d5 3. e5 d4 4. exf6 dxc3 5. fxg7 cxd2+ 6. Bxd2 Bxg7',
          why: 'The exchange spree leads to an equal position with no advantage at all.',
        },
      ],
    },
  },

  // ── 1.d4 ──────────────────────────────────────────────────────────────────
  {
    id: 'london-system',
    eco: 'D02',
    side: 'white',
    seed: '1. d4 d5 2. Nf3 Nf6 3. Bf4',
    mainline: 'e6 e3 c5 c3 Nc6 Nbd2 Bd6 Bg3 O-O Bd3',
    extraLines: {
      'c5 e3 Nc6 c3 Qb6 Qb3 c4 Qxb6 axb6': 'Damentausch nach Db6',
      'e6 e3 Bd6 Bg3 O-O Bd3 b6 Nbd2 Bb7 Ne5': 'Springer auf e5 verankern',
      'c5 e3 e6 c3 Bd6 Bg3 Nc6 Nbd2 O-O Bd3': 'Symmetrischer Aufbau',
      'Bf5 e3 e6 c4 c6 Nc3 Nbd7 Qb3 Qb6': 'Schwarz spiegelt den Aufbau',
      'g6 e3 Bg7 h3 O-O Be2 c5 c3 b6 O-O': 'Gegen den koenigsindischen Aufbau',
      'e6 e3 Bd6 Bg3 c5 c3 Nc6 Nbd2 Qc7 Bd3': 'Db6 vermeiden mit Dc7',
    },
    tags: ['system', 'solid', 'positional', 'beginnerFriendly', 'theoryLight'],
    difficulty: 1,
    popularity: 84,
    de: {
      name: 'London-System',
      summary:
        'Immer dieselbe Aufstellung, fast egal was Schwarz spielt: Bf4, e3, c3, Nbd2, Bd3. '
        + 'Ideal fuer alle, die wenig Theorie lernen und trotzdem solide stehen wollen.',
      plans: [
        'Den Aufbau Bf4, e3, Bd3, c3, Nbd2 vervollstaendigen und rochieren.',
        'Mit Ne5 den Springer zentral verankern.',
        'Am Koenigsfluegel mit Qe2, Rf1–e1 und e3–e4 vorbereiten.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. Nf3 Nf6 3. Bf4 c5 4. e3 Qb6 5. Nc3 Qxb2',
          why: 'Der b2-Bauer ist nicht immer vergiftet — hier braucht Weiss Nc3 mit konkreter Kompensation.',
        },
        {
          line: '1. d4 d5 2. Bf4 Nf6 3. e3 e6 4. Nf3 Bd6 5. Bg3 O-O 6. Bd3 b6 7. Nbd2 Bb7 8. Ne5 Nbd7 9. f4',
          why: 'Der Stonewall-Aufbau ohne vorbereitete Deckung des Feldes e4 schwaecht die eigene Koenigsstellung.',
        },
      ],
    },
    en: {
      name: 'London System',
      summary:
        'The same setup almost regardless of what Black plays: Bf4, e3, c3, Nbd2, Bd3. '
        + 'Ideal for anyone who wants a solid position without learning much theory.',
      plans: [
        'Complete the Bf4, e3, Bd3, c3, Nbd2 setup and castle.',
        'Anchor a knight centrally with Ne5.',
        'Prepare kingside play with Qe2, Rf1–e1 and e3–e4.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. Nf3 Nf6 3. Bf4 c5 4. e3 Qb6 5. Nc3 Qxb2',
          why: 'The b2 pawn is not always poisoned — here White needs Nc3 with concrete compensation.',
        },
        {
          line: '1. d4 d5 2. Bf4 Nf6 3. e3 e6 4. Nf3 Bd6 5. Bg3 O-O 6. Bd3 b6 7. Nbd2 Bb7 8. Ne5 Nbd7 9. f4',
          why: 'A Stonewall setup without covering e4 first weakens your own king.',
        },
      ],
    },
  },
  {
    id: 'queens-gambit',
    eco: 'D06',
    side: 'white',
    seed: '1. d4 d5 2. c4',
    mainline: 'e6 Nc3 Nf6 Bg5 Be7 e3 O-O Nf3',
    tags: ['classical', 'positional', 'theoryHeavy'],
    difficulty: 3,
    popularity: 90,
    de: {
      name: 'Damengambit',
      summary:
        'Kein echtes Gambit: Weiss bekommt den Bauern zurueck und bekaempft das schwarze Zentrum von der Seite. '
        + 'Die klassische Grundlage jedes 1.d4-Repertoires.',
      plans: [
        'Den Druck auf d5 halten und Schwarz zum Nachgeben zwingen.',
        'Den Minoritaetsangriff mit b4–b5 auf der Damenseite vorbereiten.',
        'Nach cxd5 exd5 auf der halboffenen c-Linie spielen.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. c4 dxc4 3. e3 b5 4. a4 c6 5. axb5 cxb5 6. Qf3',
          why: 'Den Bauern c4 halten zu wollen kostet Schwarz die Stellung — Weiss holt ihn ohnehin zurueck.',
        },
        {
          line: '1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 Nbd7 5. cxd5 exd5 6. Nxd5 Nxd5 7. Bxd8 Bb4+',
          why: 'Die beruehmte Falle: der Bauer d5 ist vergiftet, Schwarz gewinnt die Figur mit Bb4+ zurueck.',
        },
      ],
    },
    en: {
      name: 'Queen’s Gambit',
      summary:
        'Not a real gambit: White regains the pawn and fights Black’s centre from the side. '
        + 'The classical foundation of any 1.d4 repertoire.',
      plans: [
        'Keep the pressure on d5 and make Black concede.',
        'Prepare the minority attack with b4–b5 on the queenside.',
        'After cxd5 exd5, play on the half-open c-file.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. c4 dxc4 3. e3 b5 4. a4 c6 5. axb5 cxb5 6. Qf3',
          why: 'Trying to hold the c4 pawn wrecks Black’s position — White regains it anyway.',
        },
        {
          line: '1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 Nbd7 5. cxd5 exd5 6. Nxd5 Nxd5 7. Bxd8 Bb4+',
          why: 'The famous trap: the d5 pawn is poisoned, Black wins the piece back with Bb4+.',
        },
      ],
    },
  },
  {
    id: 'catalan',
    eco: 'E00',
    side: 'white',
    seed: '1. d4 Nf6 2. c4 e6 3. g3',
    mainline: 'd5 Bg2 Be7 Nf3 O-O O-O dxc4 Qc2',
    tags: ['positional', 'solid', 'theoryHeavy'],
    difficulty: 4,
    popularity: 72,
    de: {
      name: 'Katalanisch',
      summary:
        'Der Laeufer auf g2 druckt die ganze Partie ueber auf die lange Diagonale. '
        + 'Weiss opfert oft zeitweise den c4-Bauern und bekommt dafuer dauerhaften Druck.',
      plans: [
        'Den Bauern c4 mit Qc2 oder a4 zurueckholen.',
        'Auf der langen Diagonale a8–h1 gegen b7 und c6 druecken.',
        'Mit e4 im richtigen Moment das Zentrum sprengen.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 dxc4 5. Nf3 b5 6. a4 c6 7. axb5 cxb5 8. Ne5',
          why: 'Den Bauern mit b5 halten zu wollen zerstoert die eigene Damenseite.',
        },
        {
          line: '1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 Be7 5. Nf3 O-O 6. O-O dxc4 7. Ne5 Nc6 8. Bxc6 bxc6 9. Nxc6 Qe8 10. Nxe7+ Qxe7',
          why: 'Der Abtausch des Katalanen-Laeufers gibt genau die Figur auf, die die Eroeffnung ausmacht.',
        },
      ],
    },
    en: {
      name: 'Catalan',
      summary:
        'The g2 bishop presses along the long diagonal all game. '
        + 'White often gives up the c4 pawn temporarily and gets lasting pressure in return.',
      plans: [
        'Regain the c4 pawn with Qc2 or a4.',
        'Press on the a8–h1 diagonal against b7 and c6.',
        'Break with e4 at the right moment.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 dxc4 5. Nf3 b5 6. a4 c6 7. axb5 cxb5 8. Ne5',
          why: 'Trying to keep the pawn with b5 shreds your own queenside.',
        },
        {
          line: '1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 Be7 5. Nf3 O-O 6. O-O dxc4 7. Ne5 Nc6 8. Bxc6 bxc6 9. Nxc6 Qe8 10. Nxe7+ Qxe7',
          why: 'Trading the Catalan bishop gives up the very piece the opening is built around.',
        },
      ],
    },
  },
  {
    id: 'trompowsky',
    eco: 'A45',
    side: 'white',
    seed: '1. d4 Nf6 2. Bg5',
    mainline: 'Ne4 Bf4 d5 e3 c5 Bd3',
    tags: ['theoryLight', 'flexible', 'positional'],
    difficulty: 2,
    popularity: 42,
    de: {
      name: 'Trompowsky-Angriff',
      summary:
        'Sofort Bg5 — Weiss stellt die Theoriefrage, bevor Schwarz sein Lieblingssystem aufbauen kann. '
        + 'Wenig Varianten, viel eigenes Verstaendnis.',
      plans: [
        'Den Springer f6 abtauschen und auf die Bauernstruktur spielen.',
        'Bei Ne4 den Laeufer nach f4 oder h4 zuruecknehmen und Zeit gewinnen.',
        'Mit c4 und Nc3 doch noch ein Damengambit-Bild ansteuern.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. Bg5 e6 3. e4 h6 4. Bxf6 Qxf6 5. Nf3 d6 6. Nc3 g5',
          why: 'Der Bauernvorstoss g5 schwaecht den eigenen Koenig mehr, als er Weiss stoert.',
        },
        {
          line: '1. d4 Nf6 2. Bg5 c5 3. Bxf6 gxf6 4. d5 Qb6 5. Qc1',
          why: 'Die Dame nach c1 zurueckzuziehen ist passiv — der b2-Bauer ist einen Gegenangriff wert.',
        },
      ],
    },
    en: {
      name: 'Trompowsky Attack',
      summary:
        'Bg5 at once — White poses the theoretical question before Black can set up a favourite system. '
        + 'Few variations, a lot of understanding.',
      plans: [
        'Trade off the f6 knight and play on the pawn structure.',
        'Against Ne4, retreat the bishop to f4 or h4 and gain time.',
        'Transpose towards a Queen’s Gambit picture with c4 and Nc3.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. Bg5 e6 3. e4 h6 4. Bxf6 Qxf6 5. Nf3 d6 6. Nc3 g5',
          why: 'The g5 push weakens Black’s own king more than it bothers White.',
        },
        {
          line: '1. d4 Nf6 2. Bg5 c5 3. Bxf6 gxf6 4. d5 Qb6 5. Qc1',
          why: 'Retreating the queen to c1 is passive — the b2 pawn is worth a counterattack.',
        },
      ],
    },
  },
  {
    id: 'jobava-london',
    eco: 'D00',
    side: 'white',
    seed: '1. d4 Nf6 2. Nc3 d5 3. Bf4',
    mainline: 'e6 e3 Bd6 Bg3 O-O Bd3 c5 Nb5',
    extraLines: {
      'a6 e3 e6 Nf3 c5 dxc5 Bxc5 Bd3': 'a6 gegen Sb5 vorbeugend',
      'c5 e4 cxd4 Nxd5 Nxd5 exd5 Qxd5 Bxb8': 'Scharfes Bauernopfer mit e4',
      'e6 Nb5 Na6 e3 Be7 Nf3 O-O c3': 'Sofort Sb5',
      'Bf5 f3 e6 g4 Bg6 h4 h6 Nxd5': 'Aggressives f3 und g4',
      'c6 e3 Bf5 f3 e6 g4 Bg6 h4': 'Slawischer Aufbau gegen den Sturm',
      'g6 e3 Bg7 h4 h5 Be2 O-O Nf3': 'Gegen den Fianchetto-Aufbau',
    },
    tags: ['attacking', 'theoryLight', 'system'],
    difficulty: 2,
    popularity: 46,
    de: {
      name: 'Jobava-London',
      summary:
        'Die scharfe Schwester des London-Systems: Nc3 statt c3, dazu oft schnelles Nb5 und f3–e4. '
        + 'Im Blitz eine der unangenehmsten Waffen gegen 1…d5.',
      plans: [
        'Mit Nb5 den Laeufer d6 abtauschen oder den Bauern c7 angreifen.',
        'Mit f3 und e4 das Zentrum sprengen.',
        'Lange rochieren und mit h4–h5 stuermen.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. Nc3 d5 3. Bf4 a6 4. e3 e6 5. Nf3 c5 6. Ne5 Nc6 7. Bb5 Bd7 8. Nxd7 Qxd7 9. Bxc6 Qxc6',
          why: 'Beide Laeufer abzutauschen nimmt der Stellung genau die Kraft, wegen der man sie gewaehlt hat.',
        },
        {
          line: '1. d4 Nf6 2. Nc3 d5 3. Bf4 c5 4. e4 dxe4 5. d5 Nxd5 6. Nxd5 Qxd5 7. Qxd5',
          why: 'Der Abtausch der Damen verschenkt die gesamte Initiative des Gambits.',
        },
      ],
    },
    en: {
      name: 'Jobava London',
      summary:
        'The sharp sister of the London System: Nc3 instead of c3, often with a quick Nb5 and f3–e4. '
        + 'One of the nastiest blitz weapons against 1…d5.',
      plans: [
        'Use Nb5 to trade off the d6 bishop or hit the c7 pawn.',
        'Blow open the centre with f3 and e4.',
        'Castle long and storm with h4–h5.',
      ],
      mistakes: [
        {
          line: '1. d4 Nf6 2. Nc3 d5 3. Bf4 a6 4. e3 e6 5. Nf3 c5 6. Ne5 Nc6 7. Bb5 Bd7 8. Nxd7 Qxd7 9. Bxc6 Qxc6',
          why: 'Trading both bishops removes exactly the punch you chose this line for.',
        },
        {
          line: '1. d4 Nf6 2. Nc3 d5 3. Bf4 c5 4. e4 dxe4 5. d5 Nxd5 6. Nxd5 Qxd5 7. Qxd5',
          why: 'Trading queens throws away the gambit’s entire initiative.',
        },
      ],
    },
  },
  {
    id: 'colle-system',
    eco: 'D04',
    side: 'white',
    seed: '1. d4 d5 2. Nf3 Nf6 3. e3',
    mainline: 'e6 Bd3 c5 c3 Nc6 Nbd2 Bd6 O-O',
    tags: ['system', 'solid', 'beginnerFriendly', 'theoryLight'],
    difficulty: 1,
    popularity: 30,
    de: {
      name: 'Colle-System',
      summary:
        'Ein ruhiger Aufbau mit e3, Bd3, c3 und Nbd2, der auf den Durchbruch e3–e4 zielt. '
        + 'Sehr leicht zu lernen, weil Weiss fast immer dieselben Zuege macht.',
      plans: [
        'Den Aufbau vervollstaendigen und dann e3–e4 vorbereiten.',
        'Nach e4 den Laeufer d3 gegen h7 arbeiten lassen.',
        'Den Springer d2 ueber f1 nach g3 bringen, wenn es ruhig bleibt.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. Nf3 Nf6 3. e3 Bf5 4. Bd3 Bxd3 5. Qxd3 e6 6. O-O Bd6 7. c4 c6 8. Nc3 Nbd7 9. e4',
          why: 'e4 ohne fertige Entwicklung oeffnet die Stellung zum eigenen Nachteil.',
        },
        {
          line: '1. d4 d5 2. Nf3 Nf6 3. e3 g6 4. Bd3 Bg7 5. Nbd2 O-O 6. O-O c5 7. c3 Nc6 8. e4',
          why: 'Gegen den Koenigsindischen Aufbau ist e4 verfrueht — erst Re1 und Qe2.',
        },
      ],
    },
    en: {
      name: 'Colle System',
      summary:
        'A quiet setup with e3, Bd3, c3 and Nbd2 aiming at the e3–e4 break. '
        + 'Very easy to learn because White plays almost the same moves every time.',
      plans: [
        'Complete the setup, then prepare e3–e4.',
        'After e4, let the d3 bishop work against h7.',
        'Route the d2 knight via f1 to g3 in quiet positions.',
      ],
      mistakes: [
        {
          line: '1. d4 d5 2. Nf3 Nf6 3. e3 Bf5 4. Bd3 Bxd3 5. Qxd3 e6 6. O-O Bd6 7. c4 c6 8. Nc3 Nbd7 9. e4',
          why: 'e4 before development is finished opens the position to your own disadvantage.',
        },
        {
          line: '1. d4 d5 2. Nf3 Nf6 3. e3 g6 4. Bd3 Bg7 5. Nbd2 O-O 6. O-O c5 7. c3 Nc6 8. e4',
          why: 'Against a King’s Indian setup e4 is premature — play Re1 and Qe2 first.',
        },
      ],
    },
  },

  // ── Flankeneroeffnungen ───────────────────────────────────────────────────
  {
    id: 'english-symmetrical',
    eco: 'A30',
    side: 'white',
    seed: '1. c4 c5',
    mainline: 'Nf3 Nf6 g3 b6 Bg2 Bb7 O-O e6 Nc3 Be7 d4',
    tags: ['positional', 'flexible', 'closed'],
    difficulty: 3,
    popularity: 56,
    de: {
      name: 'Englisch — Symmetrisch',
      summary:
        'Beide Seiten spiegeln sich; Weiss versucht, seinen Zug Vorsprung in einen kleinen Vorteil zu verwandeln. '
        + 'Sehr flexibel, oft geht es in Damengambit- oder Igelstellungen ueber.',
      plans: [
        'Mit g3 und Bg2 die lange Diagonale besetzen.',
        'Im richtigen Moment d2–d4 spielen und ins Damengambit uebergehen.',
        'Auf der halboffenen c-Linie mit Turm und Dame druecken.',
      ],
      mistakes: [
        {
          line: '1. c4 c5 2. Nf3 Nf6 3. d4 cxd4 4. Nxd4 e5 5. Nb5 d5',
          why: 'Der Springerausflug nach b5 gibt Schwarz mit d5 sofort das Zentrum.',
        },
        {
          line: '1. c4 c5 2. Nc3 Nc6 3. g3 g6 4. Bg2 Bg7 5. Nf3 Nf6 6. O-O O-O 7. d4 cxd4 8. Nxd4 Nxd4 9. Qxd4 d6 10. Qd3',
          why: 'Die Dame in der Mitte wird bald angegriffen — Qd3 verliert Zeit gegenueber Qh4 oder Qd2.',
        },
      ],
    },
    en: {
      name: 'English — Symmetrical',
      summary:
        'Both sides mirror each other; White tries to convert the extra tempo into a small edge. '
        + 'Very flexible, often transposing into Queen’s Gambit or Hedgehog structures.',
      plans: [
        'Take the long diagonal with g3 and Bg2.',
        'Play d2–d4 at the right moment and transpose to the Queen’s Gambit.',
        'Press on the half-open c-file with rook and queen.',
      ],
      mistakes: [
        {
          line: '1. c4 c5 2. Nf3 Nf6 3. d4 cxd4 4. Nxd4 e5 5. Nb5 d5',
          why: 'The knight trip to b5 lets Black seize the centre immediately with d5.',
        },
        {
          line: '1. c4 c5 2. Nc3 Nc6 3. g3 g6 4. Bg2 Bg7 5. Nf3 Nf6 6. O-O O-O 7. d4 cxd4 8. Nxd4 Nxd4 9. Qxd4 d6 10. Qd3',
          why: 'The queen in the middle will be harassed — Qd3 loses time compared to Qh4 or Qd2.',
        },
      ],
    },
  },
  {
    id: 'english-reversed-sicilian',
    eco: 'A20',
    side: 'white',
    seed: '1. c4 e5',
    mainline: 'Nc3 Nf6 Nf3 Nc6 g3 d5 cxd5 Nxd5 Bg2',
    tags: ['positional', 'flexible', 'open'],
    difficulty: 3,
    popularity: 50,
    de: {
      name: 'Englisch — Umgekehrtes Sizilianisch',
      summary:
        'Dieselben Strukturen wie im Sizilianer, nur mit einem Tempo mehr und den Farben vertauscht. '
        + 'Wer Sizilianisch mit Schwarz kennt, findet sich hier sofort zurecht.',
      plans: [
        'Mit g3 und Bg2 gegen den Bauern d5 arbeiten.',
        'Auf der Damenseite mit b4 und Rb1 Raum gewinnen.',
        'Den Springer nach d5 bringen, wenn Schwarz ihn nicht vertreiben kann.',
      ],
      mistakes: [
        {
          line: '1. c4 e5 2. Nc3 Nf6 3. Nf3 e4 4. Ng5 b5',
          why: 'Der Bauernvorstoss e4 ohne Vorbereitung verliert den Bauern nach Ngxe4.',
        },
        {
          line: '1. c4 e5 2. g3 c6 3. d4 exd4 4. Qxd4 d5 5. Bg2 Nf6 6. Nf3 Be7 7. O-O O-O 8. Qd1',
          why: 'Die Dame drei Mal zu ziehen kostet genau den Vorteil, den der Anzug gibt.',
        },
      ],
    },
    en: {
      name: 'English — Reversed Sicilian',
      summary:
        'The same structures as the Sicilian, with an extra tempo and colours reversed. '
        + 'If you know the Sicilian as Black, you will feel at home here.',
      plans: [
        'Work against the d5 pawn with g3 and Bg2.',
        'Gain queenside space with b4 and Rb1.',
        'Post a knight on d5 when Black cannot chase it away.',
      ],
      mistakes: [
        {
          line: '1. c4 e5 2. Nc3 Nf6 3. Nf3 e4 4. Ng5 b5',
          why: 'Pushing e4 without preparation loses the pawn to Ngxe4.',
        },
        {
          line: '1. c4 e5 2. g3 c6 3. d4 exd4 4. Qxd4 d5 5. Bg2 Nf6 6. Nf3 Be7 7. O-O O-O 8. Qd1',
          why: 'Moving the queen three times costs exactly the advantage of the first move.',
        },
      ],
    },
  },
  {
    id: 'reti-opening',
    eco: 'A09',
    side: 'white',
    seed: '1. Nf3 d5 2. c4',
    mainline: 'e6 g3 Nf6 Bg2 Be7 O-O O-O b3',
    tags: ['positional', 'flexible', 'theoryLight'],
    difficulty: 3,
    popularity: 48,
    de: {
      name: 'Reti-Eroeffnung',
      summary:
        'Weiss greift das Zentrum von der Flanke an, statt es zu besetzen. '
        + 'Hypermodern und sehr flexibel — der Uebergang in Englisch oder Katalanisch steht immer offen.',
      plans: [
        'Mit g3, Bg2 und b3, Bb2 beide Diagonalen besetzen.',
        'Den Bauern d5 unter Druck setzen, statt ihn zu blockieren.',
        'Im richtigen Moment d4 oder e4 spielen und das Zentrum uebernehmen.',
      ],
      mistakes: [
        {
          line: '1. Nf3 d5 2. c4 d4 3. b4 e5 4. Nxe5',
          why: 'Der Vorstoss e5 haengt einfach — der Springer f3 schlaegt ihn.',
        },
        {
          line: '1. Nf3 d5 2. c4 dxc4 3. Na3 c5 4. Nxc4 Nc6 5. b3 e5 6. Bb2 f6',
          why: 'Das Zentrum mit Bauern zu halten laesst die weissen Laeufer erstarken.',
        },
      ],
    },
    en: {
      name: 'Réti Opening',
      summary:
        'White attacks the centre from the flank instead of occupying it. '
        + 'Hypermodern and very flexible — transposing to the English or Catalan is always available.',
      plans: [
        'Take both diagonals with g3, Bg2 and b3, Bb2.',
        'Pressure the d5 pawn rather than blockading it.',
        'Play d4 or e4 at the right moment and take over the centre.',
      ],
      mistakes: [
        {
          line: '1. Nf3 d5 2. c4 d4 3. b4 e5 4. Nxe5',
          why: 'The e5 push simply hangs — the f3 knight takes it.',
        },
        {
          line: '1. Nf3 d5 2. c4 dxc4 3. Na3 c5 4. Nxc4 Nc6 5. b3 e5 6. Bb2 f6',
          why: 'Holding the centre with pawns only strengthens White’s bishops.',
        },
      ],
    },
  },
  {
    id: 'kings-indian-attack',
    eco: 'A07',
    side: 'white',
    seed: '1. Nf3 d5 2. g3',
    mainline: 'Nf6 Bg2 e6 O-O Be7 d3 O-O Nbd2 c5 e4',
    tags: ['system', 'attacking', 'theoryLight', 'beginnerFriendly'],
    difficulty: 2,
    popularity: 40,
    de: {
      name: 'Koenigsindischer Angriff',
      summary:
        'Das Koenigsindische Bild mit Weiss und einem Tempo mehr: Nf3, g3, Bg2, d3, Nbd2, e4. '
        + 'Immer derselbe Aufbau, danach ein klarer Angriff am Koenigsfluegel.',
      plans: [
        'Den Aufbau vervollstaendigen und dann e4–e5 vorstossen.',
        'Den Springer ueber f1 nach h2 oder g5 bringen.',
        'Mit h4–h5 die Bauern gegen den schwarzen Koenig werfen.',
      ],
      mistakes: [
        {
          line: '1. Nf3 d5 2. g3 c5 3. Bg2 Nc6 4. O-O e5 5. d3 Nf6 6. Nbd2 Be7 7. e4 O-O 8. exd5 Nxd5',
          why: 'Der Abtausch auf d5 loest genau die Spannung auf, aus der der Angriff lebt.',
        },
        {
          line: '1. Nf3 d5 2. g3 Nf6 3. Bg2 c6 4. O-O Bg4 5. d3 Nbd7 6. Nbd2 e5 7. e4 dxe4 8. dxe4 Bc5 9. Qe2 O-O 10. h3 Bxf3 11. Nxf3 Qb6 12. Kh2',
          why: 'Den Koenig nach h2 zu stellen, bevor der Angriff laeuft, verliert nur Zeit.',
        },
      ],
    },
    en: {
      name: 'King’s Indian Attack',
      summary:
        'The King’s Indian picture with White and an extra tempo: Nf3, g3, Bg2, d3, Nbd2, e4. '
        + 'Always the same setup, then a clear kingside attack.',
      plans: [
        'Complete the setup, then push e4–e5.',
        'Route the knight via f1 to h2 or g5.',
        'Throw the h-pawn at the black king with h4–h5.',
      ],
      mistakes: [
        {
          line: '1. Nf3 d5 2. g3 c5 3. Bg2 Nc6 4. O-O e5 5. d3 Nf6 6. Nbd2 Be7 7. e4 O-O 8. exd5 Nxd5',
          why: 'Trading on d5 releases exactly the tension the attack lives on.',
        },
        {
          line: '1. Nf3 d5 2. g3 Nf6 3. Bg2 c6 4. O-O Bg4 5. d3 Nbd7 6. Nbd2 e5 7. e4 dxe4 8. dxe4 Bc5 9. Qe2 O-O 10. h3 Bxf3 11. Nxf3 Qb6 12. Kh2',
          why: 'Tucking the king on h2 before the attack is running only loses time.',
        },
      ],
    },
  },
  {
    id: 'bird-opening',
    eco: 'A02',
    side: 'white',
    seed: '1. f4',
    mainline: 'd5 Nf3 Nf6 e3 g6 Be2 Bg7 O-O O-O d3',
    tags: ['attacking', 'theoryLight', 'closed'],
    difficulty: 2,
    popularity: 18,
    de: {
      name: 'Bird-Eroeffnung',
      summary:
        'Ein Hollaendisch mit Weiss und einem Tempo mehr. '
        + 'Selten gespielt, deshalb sitzt der Gegner oft schon nach fuenf Zuegen ohne Vorbereitung da.',
      plans: [
        'Den Stonewall mit d4, e3, c3 und Ne5 aufbauen.',
        'Die halboffene f-Linie fuer den Turm nutzen.',
        'Den Laeufer nach b2 fianchettieren und auf e5 druecken.',
      ],
      mistakes: [
        {
          line: '1. f4 e5 2. fxe5 d6 3. exd6 Bxd6',
          why: 'Das Froms Gambit anzunehmen ist gefaehrlich; 2. e4 mit Uebergang ins Koenigsgambit ist sicherer.',
        },
        {
          line: '1. f4 d5 2. Nf3 Nf6 3. e3 Bg4 4. Be2 Nbd7 5. O-O e6 6. d3 Bd6 7. Nbd2 O-O 8. Qe1 c5 9. e4 dxe4 10. dxe4 Bc7 11. e5',
          why: 'e5 zu frueh sperrt die eigenen Figuren aus, statt Angriff zu erzeugen.',
        },
      ],
    },
    en: {
      name: 'Bird’s Opening',
      summary:
        'A Dutch with White and an extra tempo. '
        + 'Rarely played, so the opponent is often out of preparation within five moves.',
      plans: [
        'Build the Stonewall with d4, e3, c3 and Ne5.',
        'Use the half-open f-file for a rook.',
        'Fianchetto to b2 and press on e5.',
      ],
      mistakes: [
        {
          line: '1. f4 e5 2. fxe5 d6 3. exd6 Bxd6',
          why: 'Accepting From’s Gambit is dangerous; 2. e4 transposing to the King’s Gambit is safer.',
        },
        {
          line: '1. f4 d5 2. Nf3 Nf6 3. e3 Bg4 4. Be2 Nbd7 5. O-O e6 6. d3 Bd6 7. Nbd2 O-O 8. Qe1 c5 9. e4 dxe4 10. dxe4 Bc7 11. e5',
          why: 'e5 too early shuts out your own pieces instead of creating an attack.',
        },
      ],
    },
  },
];
