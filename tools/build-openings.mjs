// Erzeugt die Bibliotheksdaten der App unter app/assets/data/openings/.
//
// Quelle der Varianten ist `lichess-org/chess-openings` (CC0): rund 3.800
// benannte Linien mit ECO-Code. Fuer jede Bibliothekseroeffnung werden alle
// Linien gesammelt, die auf ihrer Startfolge aufbauen, zu einem Baum
// verschmolzen und als PGN geschrieben. Jeder benannte Endpunkt bekommt
// seinen Namen als Kommentar — dadurch traegt der Variantenbaum die
// Erklaerung gleich mit.
//
//     node tools/build-openings.mjs

import { mkdir, readdir, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { loadEcoLines, startsWith, sanSequence } from './lib/eco.mjs';
import {
  countLines,
  countNodes,
  insertLine,
  maxDepth,
  prune,
  sortTree,
  writePgn,
} from './lib/tree.mjs';
import { whiteOpenings } from './data/openings.white.mjs';
import { blackOpenings } from './data/openings.black.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, '..', 'app', 'assets', 'data', 'openings');

/** Wie weit ueber die Startfolge hinaus der Baum reicht, in Halbzuegen. */
const EXTRA_PLIES = 14;

/** Obergrenze je Eroeffnung — darueber wird die Bibliothek unuebersichtlich. */
const MAX_NODES = 160;

/**
 * Kuerzt den Baum auf [limit] Knoten, indem die tiefsten Blaetter zuerst
 * wegfallen. Die kurzen, wichtigen Zuege bleiben damit erhalten.
 */
function limitNodes(roots, limit) {
  while (countNodes(roots) > limit) {
    let deepest = null;
    let deepestDepth = -1;
    let deepestParent = null;

    const walk = (level, depth, parent) => {
      for (const node of level) {
        if (node.children.length === 0) {
          if (depth > deepestDepth) {
            deepest = node;
            deepestDepth = depth;
            deepestParent = parent;
          }
        } else {
          walk(node.children, depth + 1, node.children);
        }
      }
    };
    walk(roots, 0, roots);

    if (!deepest) break;
    const level = deepestParent ?? roots;
    const index = level.indexOf(deepest);
    if (index < 0) break;
    level.splice(index, 1);
  }
  return roots;
}

/** Wandelt einen Eintrag aus den Datendateien in die Asset-Form. */
function buildOpening(entry, ecoLines) {
  const seed = sanSequence(entry.seed);
  const maxPly = seed.length + EXTRA_PLIES;

  // `roots` haelt nur die Fortsetzungen *nach* der Startfolge; die Startfolge
  // selbst kommt weiter unten davor.
  const roots = [];
  let matched = 0;

  // Die Hauptvariante aus den Daten sichert zu, dass jede Eroeffnung eine
  // durchgehende Linie hat — auch die, zu denen die ECO-Datenbank nichts
  // Tieferes kennt.
  if (entry.mainline) {
    insertLine(roots, entry.mainline.split(/\s+/), null);
  }

  // Handverlesene Fortsetzungen fuer Eroeffnungen, zu denen die ECO-Datenbank
  // kaum benannte Linien fuehrt — sonst bliebe der Baum ein einzelner Strang.
  for (const [line, name] of Object.entries(entry.extraLines ?? {})) {
    insertLine(roots, line.split(/\s+/), name || null);
  }

  for (const line of ecoLines) {
    if (line.san.length <= seed.length) continue;
    if (!startsWith(line.san, seed)) continue;

    matched++;
    const continuation = line.san.slice(seed.length, maxPly);
    if (continuation.length === 0) continue;
    // Der Name gehoert an den Zug, der die Linie ausmacht — nur wenn die
    // Linie nicht schon gekuerzt wurde, ist er dort auch korrekt.
    const comment = line.san.length <= maxPly ? line.name : null;
    insertLine(roots, continuation, comment);
  }

  if (roots.length === 0) {
    throw new Error(
      `${entry.id}: weder ECO-Linien noch eine Hauptvariante fuer `
        + `„${entry.seed}".`,
    );
  }

  const mainline = entry.mainline ? entry.mainline.split(/\s+/) : [];
  prune(roots, 4);
  limitNodes(roots, MAX_NODES);
  sortTree(roots, mainline);

  // Der Baum beginnt an der Grundstellung, nicht erst bei der Startfolge —
  // so laesst er sich unveraendert als Repertoire uebernehmen.
  const fullTree = [];
  const seedComment = entry.de.name;
  insertLine(fullTree, seed, seedComment);

  let cursor = fullTree;
  let node = null;
  for (const move of seed) {
    node = cursor.find((child) => child.san === move);
    cursor = node.children;
  }
  node.children = roots;

  const pgn = writePgn(fullTree, {
    Event: entry.de.name,
    Site: 'MasterOpening',
    ECO: entry.eco,
    Opening: entry.en.name,
    Result: '*',
  });

  return {
    id: entry.id,
    eco: entry.eco,
    side: entry.side,
    seed: entry.seed,
    tags: entry.tags,
    difficulty: entry.difficulty,
    popularity: entry.popularity,
    namedLines: matched,
    nodeCount: countNodes(fullTree),
    lineCount: countLines(fullTree),
    maxDepth: maxDepth(fullTree),
    pgn,
    name: { de: entry.de.name, en: entry.en.name },
    summary: { de: entry.de.summary, en: entry.en.summary },
    plans: { de: entry.de.plans, en: entry.en.plans },
    mistakes: entry.de.mistakes.map((mistake, index) => ({
      line: mistake.line,
      why: { de: mistake.why, en: entry.en.mistakes[index].why },
    })),
  };
}

async function main() {
  const entries = [...whiteOpenings, ...blackOpenings];

  const ids = new Set();
  for (const entry of entries) {
    if (ids.has(entry.id)) throw new Error(`Doppelte ID: ${entry.id}`);
    ids.add(entry.id);
    if (entry.de.mistakes.length !== entry.en.mistakes.length) {
      throw new Error(`${entry.id}: Fehlerlisten sind unterschiedlich lang.`);
    }
    if (entry.de.plans.length !== entry.en.plans.length) {
      throw new Error(`${entry.id}: Planlisten sind unterschiedlich lang.`);
    }
  }

  process.stdout.write('ECO-Datenbank laden … ');
  const ecoLines = await loadEcoLines();
  process.stdout.write(`${ecoLines.length} benannte Linien\n\n`);

  // Nicht das ganze Verzeichnis loeschen: unter Windows sperrt der
  // Suchindexer es gelegentlich und `rmdir` scheitert mit EBUSY. Stattdessen
  // werden Dateien ueberschrieben und am Ende die uebrig gebliebenen entfernt.
  await mkdir(outDir, { recursive: true });
  const stale = new Set(await readdir(outDir));

  const index = [];

  for (const entry of entries) {
    const opening = buildOpening(entry, ecoLines);
    stale.delete(`${opening.id}.json`);
    await writeFile(
      join(outDir, `${opening.id}.json`),
      `${JSON.stringify(opening, null, 2)}\n`,
      'utf8',
    );

    index.push({
      id: opening.id,
      eco: opening.eco,
      side: opening.side,
      seed: opening.seed,
      tags: opening.tags,
      difficulty: opening.difficulty,
      popularity: opening.popularity,
      nodeCount: opening.nodeCount,
      lineCount: opening.lineCount,
      name: opening.name,
      summary: opening.summary,
    });

    process.stdout.write(
      `${opening.id.padEnd(30)} ${String(opening.nodeCount).padStart(4)} Zuege`
        + `  ${String(opening.lineCount).padStart(3)} Varianten`
        + `  Tiefe ${String(opening.maxDepth).padStart(2)}`
        + `  (${opening.namedLines} benannte Linien)\n`,
    );
  }

  index.sort((a, b) => b.popularity - a.popularity);
  stale.delete('index.json');
  await writeFile(
    join(outDir, 'index.json'),
    `${JSON.stringify(index, null, 2)}\n`,
    'utf8',
  );

  for (const file of stale) {
    await rm(join(outDir, file), { force: true });
    process.stdout.write(`entfernt: ${file}\n`);
  }

  const white = index.filter((o) => o.side === 'white').length;
  process.stdout.write(
    `\n${index.length} Eroeffnungen geschrieben `
      + `(${white} fuer Weiss, ${index.length - white} fuer Schwarz).\n`,
  );
}

await main();
