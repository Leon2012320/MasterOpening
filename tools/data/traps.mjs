// Bekannte Eroeffnungsfallen fuer den Fallen-Modus.
//
// `line` fuehrt bis einschliesslich des Fallenzugs des Gegners; `refutation`
// ist die Widerlegung, die der Nutzer finden muss. `side` ist die Farbe, mit
// der der Nutzer spielt — also die Seite, die die Falle widerlegt.
//
// Jede Zeile wird beim Bauen von einem Test nachgespielt; ein nicht legaler
// Zug laesst den Build scheitern.

export const traps = [
  // ── Weiss widerlegt ───────────────────────────────────────────────────────
  {
    id: 'englund-gambit',
    side: 'white',
    eco: 'A40',
    line: '1. d4 e5 2. dxe5 Qe7',
    refutation: 'Nf3 Qxe5 Nc3',
    de: {
      name: 'Englund-Gambit',
      why: 'Schwarz will den Bauern zurueckholen und dabei Zeit gewinnen. Sf3 deckt e5 und entwickelt — der Bauer laesst sich nicht halten, aber Weiss behaelt den Entwicklungsvorsprung.',
    },
    en: {
      name: 'Englund Gambit',
      why: 'Black wants the pawn back with tempo. Nf3 defends e5 and develops — the pawn cannot be kept, but White keeps the development lead.',
    },
  },
  {
    id: 'damiano-defence',
    side: 'white',
    eco: 'C40',
    line: '1. e4 e5 2. Nf3 f6',
    refutation: 'Nxe5 fxe5 Qh5+',
    de: {
      name: 'Damiano-Verteidigung',
      why: 'f6 schwaecht die Diagonale zum Koenig. Das Springeropfer auf e5 ist korrekt: nach fxe5 gewinnt Dh5+ den Turm oder erzwingt den Koenigsmarsch.',
    },
    en: {
      name: 'Damiano Defence',
      why: 'f6 weakens the diagonal to the king. The knight sacrifice on e5 is sound: after fxe5, Qh5+ wins the rook or forces the king to walk.',
    },
  },
  {
    id: 'blackburne-shilling',
    side: 'white',
    eco: 'C50',
    line: '1. e4 e5 2. Nf3 Nc6 3. Bc4 Nd4',
    refutation: 'Nxe5 Qg5 Nxf7',
    de: {
      name: 'Blackburne-Schilling-Gambit',
      why: 'Schwarz hofft auf 4. Sxe5 Dg5 mit Doppelangriff. Sxf7 dreht die Falle um: die Dame haengt und der Koenig steht im Freien.',
    },
    en: {
      name: 'Blackburne Shilling Gambit',
      why: 'Black hopes for 4. Nxe5 Qg5 with a double attack. Nxf7 turns the trap around: the queen hangs and the king is exposed.',
    },
  },
  {
    id: 'legal-mate-setup',
    side: 'white',
    eco: 'C40',
    line: '1. e4 e5 2. Nf3 d6 3. Bc4 Bg4 4. Nc3 g6',
    refutation: 'Nxe5 Bxd1 Bxf7+ Ke7 Nd5#',
    de: {
      name: 'Legalls Matt',
      why: 'Der Laeufer auf g4 ist nicht wirklich gefesselt. Sxe5 opfert die Dame und setzt nach Lxd1 mit Lxf7+ und Sd5 matt.',
    },
    en: {
      name: "Legall's Mate",
      why: 'The bishop on g4 is not really pinning anything. Nxe5 offers the queen and mates after Bxd1 with Bxf7+ and Nd5.',
    },
  },
  {
    id: 'fishing-pole',
    side: 'white',
    eco: 'C65',
    line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Ng4',
    refutation: 'h3 h5 hxg4',
    de: {
      name: 'Angelrute',
      why: 'Schwarz laesst den Springer auf g4 stehen, um nach hxg4 hxg4 die h-Linie zu oeffnen. Wer den Springer erst nach h5 nimmt, kommt dem Angriff zuvor.',
    },
    en: {
      name: 'Fishing Pole',
      why: 'Black leaves the knight on g4 so that hxg4 hxg4 opens the h-file. Taking the knight only after h5 gets in first.',
    },
  },
  {
    id: 'lasker-trap-white',
    side: 'white',
    eco: 'C41',
    line: '1. e4 e5 2. Nf3 d6 3. d4 Nd7 4. Bc4 c6 5. Ng5 Nh6',
    refutation: 'Bxf7+ Nxf7 Ne6',
    de: {
      name: 'Philidor-Falle',
      why: 'Sh6 deckt f7 nur scheinbar. Lxf7+ zieht den Springer weg, danach gabelt Se6 Dame und Turm.',
    },
    en: {
      name: 'Philidor Trap',
      why: 'Nh6 only appears to cover f7. Bxf7+ drags the knight away, then Ne6 forks queen and rook.',
    },
  },
  {
    id: 'siberian-trap-avoided',
    side: 'white',
    eco: 'B22',
    line: '1. e4 c5 2. c3 Nf6 3. e5 Nd5 4. d4 cxd4 5. Nf3 Nc6 6. cxd4 d6 7. Bc4 Nb6 8. Bb5 dxe5',
    refutation: 'Nxe5 Qxd4 Nxc6',
    de: {
      name: 'Sibirische Falle (vermieden)',
      why: 'Nach dxe5 sieht d4 ungedeckt aus. Sxe5 haelt alles zusammen: Dxd4 erlaubt Sxc6 mit Angriff auf Dame und Turm.',
    },
    en: {
      name: 'Siberian Trap (avoided)',
      why: 'After dxe5 the d4 pawn looks loose. Nxe5 holds everything: Qxd4 allows Nxc6 hitting queen and rook.',
    },
  },
  {
    id: 'lolli-attack',
    side: 'white',
    eco: 'C57',
    line: '1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. Ng5 d5 5. exd5 Nxd5',
    refutation: 'd4 Be7 Nxf7',
    de: {
      name: 'Lolli-Angriff',
      why: 'Sxd5 ist der natuerliche, aber schlechte Zug. Nach d4 ist der Springer ueberlastet und Sxf7 kommt mit Wirkung.',
    },
    en: {
      name: 'Lolli Attack',
      why: 'Nxd5 is the natural but poor recapture. After d4 the knight is overloaded and Nxf7 lands with effect.',
    },
  },
  {
    id: 'cambridge-springs-white',
    side: 'white',
    eco: 'D52',
    line: '1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 Nbd7 5. e3 c6 6. Nf3 Qa5',
    refutation: 'Nd2 Bb4 Qc2',
    de: {
      name: 'Cambridge-Springs-Falle',
      why: 'Da5 zielt auf die Fesselung des Springers c3. Sd2 loest sie auf, bevor Lb4 mit Tempo kommt.',
    },
    en: {
      name: 'Cambridge Springs Trap',
      why: 'Qa5 aims at pinning the c3 knight. Nd2 unravels it before Bb4 arrives with tempo.',
    },
  },
  {
    id: 'elephant-gambit',
    side: 'white',
    eco: 'C40',
    line: '1. e4 e5 2. Nf3 d5',
    refutation: 'Nxe5 Bd6 d4',
    de: {
      name: 'Elefanten-Gambit',
      why: 'Schwarz gibt einen Bauern fuer schnelle Entwicklung. Sxe5 nimmt an und d4 haelt den Springer — ohne Kompensation steht Schwarz einfach einen Bauern hinten.',
    },
    en: {
      name: 'Elephant Gambit',
      why: 'Black gives a pawn for fast development. Nxe5 accepts and d4 holds the knight — without compensation Black is simply a pawn down.',
    },
  },
  {
    id: 'halosar-trap',
    side: 'white',
    eco: 'D00',
    line: '1. d4 d5 2. e4 dxe4 3. Nc3 Nf6 4. f3 exf3 5. Nxf3 Bg4 6. h3 Bxf3',
    refutation: 'Qxf3 c6 Bf4',
    de: {
      name: 'Blackmar-Diemer, Halosar',
      why: 'Der Abtausch auf f3 gibt Weiss die offene f-Linie und beide Laeufer. Dxf3 entwickelt mit Druck auf f7 und b7.',
    },
    en: {
      name: 'Blackmar-Diemer, Halosar',
      why: 'Trading on f3 hands White the open f-file and both bishops. Qxf3 develops with pressure on f7 and b7.',
    },
  },
  {
    id: 'monticelli-trap',
    side: 'white',
    eco: 'E11',
    line: '1. Nf3 Nf6 2. c4 e6 3. g3 b6 4. Bg2 Bb7 5. O-O Be7 6. d4 O-O 7. Nc3 Ne4',
    refutation: 'Qc2 Nxc3 Qxc3',
    de: {
      name: 'Monticelli-Falle',
      why: 'Se4 will das Feld halten. Dc2 greift den Springer an und gewinnt nach dem Abtausch Zeit fuer die Zentrumsbildung.',
    },
    en: {
      name: 'Monticelli Trap',
      why: 'Ne4 wants to hold the square. Qc2 attacks the knight and gains time for the centre after the exchange.',
    },
  },

  // ── Schwarz widerlegt ─────────────────────────────────────────────────────
  {
    id: 'scholars-mate',
    side: 'black',
    eco: 'C20',
    line: '1. e4 e5 2. Bc4 Nc6 3. Qh5',
    refutation: 'g6 Qf3 Nf6',
    de: {
      name: 'Schaefermatt',
      why: 'Dh5 droht Matt auf f7. g6 vertreibt die Dame mit Tempo — Sf6 wuerde matt erlauben, weil f7 dann nur einmal gedeckt ist.',
    },
    en: {
      name: "Scholar's Mate",
      why: 'Qh5 threatens mate on f7. g6 chases the queen with tempo — Nf6 would allow mate because f7 is then defended only once.',
    },
  },
  {
    id: 'legal-avoided',
    side: 'black',
    eco: 'C41',
    line: '1. e4 e5 2. Nf3 d6 3. Bc4 Bg4 4. Nc3 Nf6 5. Nxe5',
    refutation: 'Bxd1 Bxf7+ Ke7',
    de: {
      name: 'Legall vermieden',
      why: 'Sf6 statt g6 nimmt der Kombination die Spitze: nach Sxe5 Lxd1 Lxf7+ Ke7 ist der Koenig sicher und Schwarz hat die Dame.',
    },
    en: {
      name: 'Legall avoided',
      why: 'Nf6 instead of g6 takes the sting out: after Nxe5 Bxd1 Bxf7+ Ke7 the king is safe and Black has the queen.',
    },
  },
  {
    id: 'noahs-ark',
    side: 'black',
    eco: 'C70',
    line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 d6 5. d4 b5 6. Bb3 Nxd4 7. Nxd4 exd4 8. Qxd4',
    refutation: 'c5 Qd5 Be6 Qc6+ Bd7',
    de: {
      name: 'Arche-Noah-Falle',
      why: 'Die Bauern c5, b5 und a6 fangen den weissen Laeufer ein. Nach c5 muss die Dame ziehen, und Le6 gefolgt von Ld7 haelt alles zusammen.',
    },
    en: {
      name: "Noah's Ark Trap",
      why: 'The pawns on c5, b5 and a6 trap White’s bishop. After c5 the queen must move, and Be6 followed by Bd7 holds everything.',
    },
  },
  {
    id: 'mortimer-trap',
    side: 'black',
    eco: 'C65',
    line: '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Ne7 5. Nxe5',
    refutation: 'c6 Nc4 cxb5',
    de: {
      name: 'Mortimer-Falle',
      why: 'Sxe5 sieht nach einem Freibauern aus. c6 greift den Laeufer an und gewinnt nach dem Rueckzug die Figur zurueck.',
    },
    en: {
      name: 'Mortimer Trap',
      why: 'Nxe5 looks like a free pawn. c6 attacks the bishop and regains the piece after it retreats.',
    },
  },
  {
    id: 'lasker-trap-albin',
    side: 'black',
    eco: 'D08',
    line: '1. d4 d5 2. c4 e5 3. dxe5 d4 4. e3',
    refutation: 'Bb4+ Bd2 dxe3',
    de: {
      name: 'Lasker-Falle im Albin',
      why: 'e3 will den Bauern d4 abraeumen. Lb4+ schaltet ein Schach dazwischen; nach Ld2 dxe3 wandelt der Bauer spaeter zum Springer und gewinnt Material.',
    },
    en: {
      name: 'Lasker Trap in the Albin',
      why: 'e3 wants to remove the d4 pawn. Bb4+ inserts a check; after Bd2 dxe3 the pawn later promotes to a knight and wins material.',
    },
  },
  {
    id: 'rubinstein-trap',
    side: 'black',
    eco: 'D55',
    line: '1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 Be7 5. e3 O-O 6. Nf3 Nbd7 7. Bd3 dxc4 8. Bxc4',
    refutation: 'Nb6 Bd3 Nbd5',
    de: {
      name: 'Rubinstein-Falle (vermieden)',
      why: 'Der bekannte Fehler ist Sbd7 mit spaeterem Se4. Sb6 und Sbd5 halten die Struktur, ohne die Dame zu ueberlasten.',
    },
    en: {
      name: 'Rubinstein Trap (avoided)',
      why: 'The known mistake is Nbd7 followed by Ne4. Nb6 and Nbd5 hold the structure without overloading the queen.',
    },
  },
  {
    id: 'kieninger-trap',
    side: 'black',
    eco: 'A45',
    line: '1. d4 Nf6 2. c4 e5 3. dxe5 Ng4 4. Bf4 Nc6 5. Nf3 Bb4+ 6. Nbd2 Qe7 7. a3',
    refutation: 'Ngxe5 axb4 Nd3+',
    de: {
      name: 'Kieninger-Falle',
      why: 'a3 greift den Laeufer an und uebersieht die Gabel. Sgxe5 opfert den Laeufer, danach gewinnt Sd3+ die Dame.',
    },
    en: {
      name: 'Kieninger Trap',
      why: 'a3 attacks the bishop and misses the fork. Ngxe5 offers the bishop, then Nd3+ wins the queen.',
    },
  },
  {
    id: 'wing-gambit',
    side: 'black',
    eco: 'B20',
    line: '1. e4 c5 2. b4',
    refutation: 'cxb4 a3 d5',
    de: {
      name: 'Fluegelgambit',
      why: 'Weiss gibt einen Bauern, um den c-Bauern von der Mitte weg zu lenken. d5 im Zentrum gibt den Bauern zurueck und stellt die Balance her.',
    },
    en: {
      name: 'Wing Gambit',
      why: 'White gives a pawn to deflect the c-pawn from the centre. d5 in the centre returns the pawn and restores the balance.',
    },
  },
  {
    id: 'lisitsyn-gambit',
    side: 'black',
    eco: 'A04',
    line: '1. Nf3 f5 2. e4 fxe4 3. Ng5',
    refutation: 'Nf6 d3 e3',
    de: {
      name: 'Lisitsyn-Gambit',
      why: 'Sg5 zielt sofort auf f7 und h7. Sf6 deckt beides; der Mehrbauer laesst sich mit e3 zurueckgeben, um die Entwicklung nicht zu verlieren.',
    },
    en: {
      name: 'Lisitsyn Gambit',
      why: 'Ng5 immediately eyes f7 and h7. Nf6 covers both; the extra pawn can be returned with e3 rather than losing development.',
    },
  },
  {
    id: 'tennison-gambit',
    side: 'black',
    eco: 'A06',
    line: '1. Nf3 d5 2. e4 dxe4 3. Ng5',
    refutation: 'Nf6 Bc4 e6',
    de: {
      name: 'Tennison-Gambit',
      why: 'Die Falle ist 3…Sf6 4. d3 exd3 5. Lxd3 mit Angriff. Sf6 und e6 halten alles zusammen und geben den Bauern nicht kampflos her.',
    },
    en: {
      name: 'Tennison Gambit',
      why: 'The trap is 3…Nf6 4. d3 exd3 5. Bxd3 with an attack. Nf6 and e6 hold things together without giving the pawn back for free.',
    },
  },
  {
    id: 'fried-liver',
    side: 'black',
    eco: 'C57',
    line: '1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. Ng5 d5 5. exd5',
    refutation: 'Na5 Bb5+ c6 dxc6 bxc6',
    de: {
      name: 'Gebratene Leber (vermieden)',
      why: 'Sxd5 fuehrt in den Angriff mit Sxf7. Sa5 greift stattdessen den Laeufer an und vermeidet die ganze Komplikation.',
    },
    en: {
      name: 'Fried Liver (avoided)',
      why: 'Nxd5 walks into Nxf7. Na5 attacks the bishop instead and sidesteps the whole complication.',
    },
  },
  {
    id: 'milner-barry',
    side: 'black',
    eco: 'C02',
    line: '1. e4 e6 2. d4 d5 3. e5 c5 4. c3 Nc6 5. Nf3 Qb6 6. Bd3 cxd4 7. cxd4 Nxd4 8. Nxd4 Qxd4 9. Nc3',
    refutation: 'Qxe5+ Be2 Ne7',
    de: {
      name: 'Milner-Barry-Gambit',
      why: 'Weiss opfert einen Bauern fuer Angriff auf der c-Linie. De4+ mit Damentausch nimmt dem Gambit die Kraft.',
    },
    en: {
      name: 'Milner-Barry Gambit',
      why: 'White gives a pawn for pressure on the c-file. Qe4+ trading queens takes the punch out of the gambit.',
    },
  },
  {
    id: 'poisoned-pawn',
    side: 'black',
    eco: 'B97',
    line: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 Qb6 8. Qd2 Qxb2 9. Rb1',
    refutation: 'Qa3 f5 Be7',
    de: {
      name: 'Vergifteter Bauer',
      why: 'Nach Tb1 muss die Dame den richtigen Weg zurueck finden. Da3 haelt die Verbindung und Le7 bringt den Koenig endlich in Sicherheit.',
    },
    en: {
      name: 'Poisoned Pawn',
      why: 'After Rb1 the queen must find the right way back. Qa3 keeps the connection and Be7 finally brings the king to safety.',
    },
  },
];
