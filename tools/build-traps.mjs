// Erzeugt app/assets/data/traps.json aus tools/data/traps.mjs.
//
// Aus Fallenzug und Widerlegung wird eine durchgehende PGN-Linie; die App
// spielt daraus alles bis zum Fallenzug vor und fragt nur die Widerlegung ab.
// Die Legalitaet prueft der Dart-Test — hier gibt es keinen Schachmotor.
//
//     node tools/build-traps.mjs

import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { sanSequence } from './lib/eco.mjs';
import { writePgn, insertLine } from './lib/tree.mjs';
import { traps } from './data/traps.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, '..', 'app', 'assets', 'data');

function build(trap) {
  const setup = sanSequence(trap.line);
  const refutation = trap.refutation.split(/\s+/).filter(Boolean);

  if (setup.length === 0) throw new Error(`${trap.id}: leere Fallenlinie.`);
  if (refutation.length === 0) {
    throw new Error(`${trap.id}: keine Widerlegung angegeben.`);
  }

  // Die Widerlegung muss mit einem Zug der eigenen Farbe beginnen: der
  // Fallenzug ist der letzte der Setup-Linie, also ist danach der Nutzer dran.
  const setupIsWhiteToMove = setup.length % 2 === 0;
  const userIsWhite = trap.side === 'white';
  if (setupIsWhiteToMove !== userIsWhite) {
    throw new Error(
      `${trap.id}: nach dem Fallenzug ist ${
        setupIsWhiteToMove ? 'Weiss' : 'Schwarz'
      } am Zug, der Nutzer spielt aber ${trap.side}.`,
    );
  }

  const roots = [];
  insertLine(roots, [...setup, ...refutation], trap.de.name);

  return {
    id: trap.id,
    side: trap.side,
    eco: trap.eco,
    // Ab hier wird gefragt: alles bis einschliesslich des Fallenzugs spielt
    // die App vor.
    askFromPly: setup.length,
    pgn: writePgn(roots, {
      Event: trap.de.name,
      Site: 'MasterOpening',
      ECO: trap.eco,
      Opening: trap.en.name,
      Result: '*',
    }),
    name: { de: trap.de.name, en: trap.en.name },
    why: { de: trap.de.why, en: trap.en.why },
  };
}

async function main() {
  const ids = new Set();
  const built = [];

  for (const trap of traps) {
    if (ids.has(trap.id)) throw new Error(`Doppelte ID: ${trap.id}`);
    ids.add(trap.id);
    built.push(build(trap));
  }

  await mkdir(outDir, { recursive: true });
  await writeFile(
    join(outDir, 'traps.json'),
    `${JSON.stringify(built, null, 2)}\n`,
    'utf8',
  );

  const white = built.filter((t) => t.side === 'white').length;
  process.stdout.write(
    `${built.length} Fallen geschrieben `
      + `(${white} widerlegt Weiss, ${built.length - white} Schwarz).\n`,
  );
}

await main();
