// Zugriff auf die ECO-Datenbank von Lichess.
//
// `lichess-org/chess-openings` pflegt rund 3.800 benannte Eroeffnungslinien
// als TSV: ECO-Code, Name, Zugfolge in SAN. Das ist die Quelle fuer Namen,
// Codes und die Variantenbaeume der Bibliothek — frei lizenziert (CC0) und
// ohne Anmeldung erreichbar, anders als der Eroeffnungs-Explorer.

import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
export const cacheDir = join(here, '..', '.cache');

const BASE =
  'https://raw.githubusercontent.com/lichess-org/chess-openings/master';
const FILES = ['a.tsv', 'b.tsv', 'c.tsv', 'd.tsv', 'e.tsv'];

/** Laedt eine Datei und legt sie im Zwischenspeicher ab. */
async function cached(name, url) {
  await mkdir(cacheDir, { recursive: true });
  const file = join(cacheDir, name);
  if (existsSync(file)) return readFile(file, 'utf8');

  const response = await fetch(url, {
    headers: { 'user-agent': 'MasterOpening build script' },
  });
  if (!response.ok) {
    throw new Error(`${url} antwortete mit ${response.status}`);
  }
  const text = await response.text();
  await writeFile(file, text, 'utf8');
  return text;
}

/**
 * Zerlegt eine PGN-Zugfolge ohne Varianten in reine SAN-Zuege.
 * Die TSV-Zeilen enthalten nur Zugnummern und Zuege, keine Kommentare.
 */
export function sanSequence(pgn) {
  return pgn
    .split(/\s+/)
    .filter((token) => token && !/^\d+\.+$/.test(token) && token !== '*')
    .map((token) => token.replace(/^\d+\.+/, ''))
    .filter(Boolean);
}

/**
 * Alle benannten Linien, absteigend nach Laenge sortiert — so findet ein
 * Praefix-Vergleich immer zuerst den spezifischsten Namen.
 *
 * @returns {Promise<Array<{eco: string, name: string, san: string[]}>>}
 */
export async function loadEcoLines() {
  const lines = [];

  for (const file of FILES) {
    const text = await cached(file, `${BASE}/${file}`);
    const rows = text.split('\n').slice(1);
    for (const row of rows) {
      if (!row.trim()) continue;
      const [eco, name, pgn] = row.split('\t');
      if (!eco || !name || !pgn) continue;
      lines.push({ eco: eco.trim(), name: name.trim(), san: sanSequence(pgn) });
    }
  }

  lines.sort((a, b) => b.san.length - a.san.length);
  return lines;
}

/** Ob `prefix` der Anfang von `seq` ist. */
export function startsWith(seq, prefix) {
  if (prefix.length > seq.length) return false;
  for (let i = 0; i < prefix.length; i++) {
    if (seq[i] !== prefix[i]) return false;
  }
  return true;
}

/** Der spezifischste Name fuer eine Zugfolge. */
export function nameFor(lines, san) {
  for (const line of lines) {
    if (startsWith(san, line.san)) return line;
  }
  return null;
}
