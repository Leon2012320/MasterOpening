#!/usr/bin/env node
/**
 * Erzeugt `app/lib/core/theme/ph_icons.dart` und kopiert die Phosphor-Fonts
 * nach `app/assets/fonts/`.
 *
 * Warum nicht einfach `package:phosphor_flutter`? Dessen `PhosphorIconData`
 * leitet von `IconData` ab, und `IconData` ist seit Flutter 3.44 `final` — das
 * Paket lässt sich nicht mehr übersetzen. Symbolschrift und Codepunkte sind
 * aber unverändert brauchbar (Phosphor Icons, MIT), also binden wir beides
 * direkt ein und kommen ohne die Abhängigkeit aus.
 *
 * Aufruf:  node tools/generate-icons.mjs
 * Voraussetzung: `flutter pub get` im Ordner `app/` wurde einmal ausgeführt,
 * solange phosphor_flutter noch in der pubspec stand. Die erzeugte Datei ist
 * eingecheckt, ein erneuter Lauf ist nur bei einem Phosphor-Update nötig.
 */

import { readFile, writeFile, mkdir, copyFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const appDir = join(repoRoot, 'app');

/** Findet das entpackte phosphor_flutter im Pub-Cache über package_config.json. */
async function locatePhosphor() {
  const configPath = join(appDir, '.dart_tool', 'package_config.json');
  if (!existsSync(configPath)) {
    throw new Error(
      `${configPath} fehlt. Erst "flutter pub get" im Ordner app/ ausführen.`,
    );
  }
  const config = JSON.parse(await readFile(configPath, 'utf8'));
  const entry = config.packages.find((p) => p.name === 'phosphor_flutter');
  if (!entry) {
    throw new Error(
      'phosphor_flutter steckt nicht mehr im Package-Config. Für einen ' +
        'Neulauf einmalig "flutter pub add phosphor_flutter" ausführen.',
    );
  }
  return fileURLToPath(new URL(entry.rootUri + '/', `file://${configPath}`));
}

/** Liest `static const name = PhosphorFlatIconData(0x…, 'Style');` aus. */
async function parseIcons(file) {
  const source = await readFile(file, 'utf8');
  const pattern = /^\s*static const (\w+) = Phosphor\w*IconData\((0x[0-9a-f]+)/gim;
  const icons = [];
  for (const match of source.matchAll(pattern)) {
    icons.push({ name: match[1], code: match[2] });
  }
  icons.sort((a, b) => a.name.localeCompare(b.name));
  return icons;
}

function renderClass(className, family, docs, icons) {
  const lines = icons.map(
    (i) =>
      `  static const IconData ${i.name} = IconData(${i.code}, fontFamily: '${family}');`,
  );
  return [
    `/// ${docs}`,
    '@staticIconProvider',
    `abstract final class ${className} {`,
    ...lines,
    '}',
  ].join('\n');
}

async function main() {
  const phosphorDir = await locatePhosphor();
  const srcDir = join(phosphorDir, 'lib', 'src');
  const fontDir = join(phosphorDir, 'lib', 'fonts');

  const regular = await parseIcons(join(srcDir, 'phosphor_icons_regular.dart'));
  const fill = await parseIcons(join(srcDir, 'phosphor_icons_fill.dart'));

  if (regular.length === 0 || fill.length === 0) {
    throw new Error('Keine Symbole gefunden — hat sich das Quellformat geändert?');
  }

  const assetsDir = join(appDir, 'assets', 'fonts');
  await mkdir(assetsDir, { recursive: true });
  await copyFile(join(fontDir, 'Phosphor.ttf'), join(assetsDir, 'Phosphor-Regular.ttf'));
  await copyFile(join(fontDir, 'Phosphor-Fill.ttf'), join(assetsDir, 'Phosphor-Fill.ttf'));
  await copyFile(join(phosphorDir, 'LICENSE'), join(assetsDir, 'Phosphor-LICENSE.txt'));

  const output = `// GENERIERT von tools/generate-icons.mjs — nicht von Hand ändern.
//
// Symbolschrift: Phosphor Icons (MIT), siehe assets/fonts/Phosphor-LICENSE.txt.
// Regeneriert wird nur bei einem Phosphor-Update.

import 'package:flutter/widgets.dart';

${renderClass('PhIcons', 'PhosphorRegular', 'Phosphor im Stil „Regular" — der Normalfall in der App.', regular)}

${renderClass('PhIconsFill', 'PhosphorFill', 'Phosphor gefüllt — für aktive Zustände, etwa den laufenden Tab.', fill)}
`;

  const target = join(appDir, 'lib', 'core', 'theme', 'ph_icons.dart');
  await writeFile(target, output, 'utf8');

  console.log(
    `${regular.length} Symbole (Regular) und ${fill.length} (Fill) nach ${target} geschrieben.`,
  );
}

await main();
