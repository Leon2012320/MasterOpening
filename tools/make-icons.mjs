#!/usr/bin/env node
// Erzeugt das App-Icon aus dem Nocturne-System.
//
// Programmatisch statt als Binärdatei im Repo: so ist nachvollziehbar, woher
// jedes Pixel kommt, und eine Änderung an der Palette lässt sich nachziehen,
// ohne ein Grafikprogramm zu öffnen. Ohne Abhängigkeiten — Node bringt zlib
// mit, und PNG ist ein einfaches Format.
//
//   node tools/make-icons.mjs

import { deflateSync } from 'node:zlib';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const androidRes = join(root, 'app', 'android', 'app', 'src', 'main', 'res');

// ── Palette ──────────────────────────────────────────────────────────────────
const BG = [0x16, 0x18, 0x26, 0xff]; // Nocturne bg (dunkel)
const ACCENT = [0x96, 0x8a, 0xe0, 0xff]; // Nocturne accent

// ── PNG ──────────────────────────────────────────────────────────────────────

const crcTable = (() => {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c;
  }
  return table;
})();

function crc32(buffer) {
  let c = 0xffffffff;
  for (const byte of buffer) c = crcTable[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);

  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));

  return Buffer.concat([length, body, crc]);
}

/** RGBA-Pixel (Uint8Array, size*size*4) als PNG. */
function encodePng(pixels, size) {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(size, 0);
  header.writeUInt32BE(size, 4);
  header[8] = 8; // 8 Bit je Kanal
  header[9] = 6; // Truecolour mit Alpha
  header[10] = 0;
  header[11] = 0;
  header[12] = 0;

  // Je Zeile ein Filterbyte 0 — ohne Vorhersage, dafür trivial korrekt.
  const stride = size * 4;
  const raw = Buffer.alloc((stride + 1) * size);
  for (let y = 0; y < size; y++) {
    raw[y * (stride + 1)] = 0;
    Buffer.from(pixels.buffer, y * stride, stride).copy(
      raw,
      y * (stride + 1) + 1,
    );
  }

  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', header),
    chunk('IDAT', deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// ── Zeichnen ─────────────────────────────────────────────────────────────────

/**
 * Der Bauer, beschrieben in Einheitskoordinaten (0…1).
 *
 * Ein Bauer und keine Dame: die App handelt vom Anfang der Partie, und die
 * Silhouette bleibt auch bei 48 Pixeln erkennbar.
 */
function insidePawn(x, y) {
  // Kopf
  if ((x - 0.5) ** 2 + (y - 0.26) ** 2 <= 0.115 ** 2) return true;

  // Kragen — ein flaches Band, das den Kopf berührt statt darunter zu
  // schweben; bei 48 Pixeln fiele eine Lücke sonst als Fehler auf.
  if (y >= 0.365 && y <= 0.425 && Math.abs(x - 0.5) <= 0.175) return true;

  // Körper: von schmal unter dem Kragen nach breit zum Fuß.
  if (y > 0.425 && y < 0.7) {
    const t = (y - 0.425) / (0.7 - 0.425);
    const halfWidth = 0.085 + t * 0.08;
    if (Math.abs(x - 0.5) <= halfWidth) return true;
  }

  // Sockel
  if (y >= 0.7 && y <= 0.79 && Math.abs(x - 0.5) <= 0.245) return true;

  return false;
}

/** Abgerundetes Quadrat für das ausgefüllte Icon. */
function insideRoundedSquare(x, y, radius) {
  const dx = Math.max(radius - x, 0, x - (1 - radius));
  const dy = Math.max(radius - y, 0, y - (1 - radius));
  return dx * dx + dy * dy <= radius * radius;
}

/**
 * Malt ein Icon.
 *
 * `scale` verkleinert die Figur — der adaptive Vordergrund muss in die
 * innere Sicherheitszone passen, sonst schneidet Android ihn an.
 */
function draw({ size, withBackground, scale }) {
  const pixels = new Uint8Array(size * size * 4);
  const samples = 4; // 4×4 Überabtastung glättet die Kanten

  for (let py = 0; py < size; py++) {
    for (let px = 0; px < size; px++) {
      let inShape = 0;
      let inSquare = 0;

      for (let sy = 0; sy < samples; sy++) {
        for (let sx = 0; sx < samples; sx++) {
          const x = (px + (sx + 0.5) / samples) / size;
          const y = (py + (sy + 0.5) / samples) / size;

          if (withBackground && insideRoundedSquare(x, y, 0.22)) inSquare++;

          // Um die Mitte skalieren, damit die Figur zentriert bleibt.
          const fx = (x - 0.5) / scale + 0.5;
          const fy = (y - 0.5) / scale + 0.5;
          if (fx >= 0 && fx <= 1 && fy >= 0 && fy <= 1 && insidePawn(fx, fy)) {
            inShape++;
          }
        }
      }

      const total = samples * samples;
      const offset = (py * size + px) * 4;

      const squareAlpha = withBackground ? inSquare / total : 0;
      const shapeAlpha = inShape / total;

      // Akzent über Grund, Grund über Nichts.
      const bgA = squareAlpha;
      const fgA = shapeAlpha;
      const outA = fgA + bgA * (1 - fgA);

      if (outA === 0) {
        pixels[offset + 3] = 0;
        continue;
      }

      for (let c = 0; c < 3; c++) {
        const value =
          (ACCENT[c] * fgA + BG[c] * bgA * (1 - fgA)) / outA;
        pixels[offset + c] = Math.round(value);
      }
      pixels[offset + 3] = Math.round(outA * 255);
    }
  }

  return encodePng(pixels, size);
}

function write(path, buffer) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, buffer);
  console.log(`  ${path.slice(root.length + 1)} (${buffer.length} B)`);
}

// ── Ausgabe ──────────────────────────────────────────────────────────────────

// Die klassischen Dichten, für Android 7 und alles, was keine adaptiven
// Icons kennt.
const densities = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

console.log('App-Icon:');
for (const [folder, size] of Object.entries(densities)) {
  write(
    join(androidRes, folder, 'ic_launcher.png'),
    draw({ size, withBackground: true, scale: 0.74 }),
  );

  // Der adaptive Vordergrund ist 108 dp breit, die Figur darf nur die
  // inneren 66 dp füllen — der Rest wird je nach Gerät weggeschnitten.
  write(
    join(androidRes, folder, 'ic_launcher_foreground.png'),
    draw({
      size: Math.round((size * 108) / 48),
      withBackground: false,
      scale: 0.46,
    }),
  );
}

// Für den Play-Store-Eintrag.
write(
  join(root, 'store', 'icon-512.png'),
  draw({ size: 512, withBackground: true, scale: 0.74 }),
);

console.log('Fertig.');
