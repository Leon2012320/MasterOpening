// Baut aus vielen einzelnen Zugfolgen einen Variantenbaum und schreibt ihn
// als PGN — dasselbe Format, das die App auch sonst liest.

/**
 * @typedef {{san: string, comment: string|null, children: Node[]}} Node
 */

/** @returns {Node} */
function newNode(san) {
  return { san, comment: null, children: [] };
}

/**
 * Fuegt eine Zugfolge in den Baum ein.
 *
 * @param {Node[]} roots
 * @param {string[]} san Zugfolge ab der Wurzel.
 * @param {string|null} comment Kommentar am letzten Zug der Folge.
 */
export function insertLine(roots, san, comment = null) {
  let level = roots;
  let node = null;

  for (const move of san) {
    node = level.find((child) => child.san === move);
    if (!node) {
      node = newNode(move);
      level.push(node);
    }
    level = node.children;
  }

  // Der spezifischere Kommentar gewinnt: eine laengere Linie beschreibt ihren
  // Endpunkt genauer als eine kuerzere, die zufaellig hier vorbeikommt.
  if (node && comment && !node.comment) node.comment = comment;
}

/** Wie viele Zuege der Baum enthaelt. */
export function countNodes(roots) {
  let total = 0;
  const stack = [...roots];
  while (stack.length) {
    const node = stack.pop();
    total++;
    stack.push(...node.children);
  }
  return total;
}

/** Wie viele Blaetter — also wie viele vollstaendige Varianten. */
export function countLines(roots) {
  let total = 0;
  const stack = [...roots];
  while (stack.length) {
    const node = stack.pop();
    if (node.children.length === 0) total++;
    else stack.push(...node.children);
  }
  return total;
}

/** Die tiefste Stelle des Baums, in Halbzuegen. */
export function maxDepth(roots, depth = 0) {
  let best = depth;
  for (const node of roots) {
    const child = maxDepth(node.children, depth + 1);
    if (child > best) best = child;
  }
  return best;
}

/**
 * Schneidet Zweige ab, die kaum Substanz haben.
 *
 * Die ECO-Datenbank benennt auch Kuriositaeten; ein Ast, der nach einem
 * einzigen Zug endet und keinen Namen traegt, hilft beim Lernen nicht.
 *
 * @param {Node[]} roots
 * @param {number} minDepth Aeste unterhalb dieser Tiefe muessen benannt sein.
 */
export function prune(roots, minDepth, depth = 1) {
  return roots.filter((node) => {
    node.children = prune(node.children, minDepth, depth + 1);
    if (node.children.length > 0) return true;
    return depth >= minDepth || node.comment !== null;
  });
}

/**
 * Sortiert jede Ebene: benannte Linien nach vorn, danach die mit den meisten
 * Fortsetzungen. Das erste Kind wird zur Hauptvariante.
 */
export function sortTree(roots, mainlineHint = []) {
  const [head, ...tail] = mainlineHint;

  roots.sort((a, b) => {
    if (a.san === head) return -1;
    if (b.san === head) return 1;
    const bySize = countNodes([b]) - countNodes([a]);
    if (bySize !== 0) return bySize;
    return a.san.localeCompare(b.san);
  });

  for (const node of roots) {
    sortTree(node.children, node.san === head ? tail : []);
  }
  return roots;
}

/**
 * Schreibt den Baum als PGN.
 *
 * Die erste Fortsetzung einer Ebene laeuft in der Hauptlinie weiter, alle
 * weiteren stehen als Klammervariante dahinter — genau so, wie `PgnIo` es
 * wieder einliest.
 */
export function writePgn(roots, headers = {}) {
  const head = Object.entries(headers)
    .map(([key, value]) => `[${key} "${String(value).replaceAll('"', "'")}"]`)
    .join('\n');

  /**
   * Nur der Zug selbst, mit Nummer und Kommentar — ohne Fortsetzung.
   * @param {Node} node
   */
  function renderMove(node, ply, needsNumber) {
    const moveNumber = Math.floor((ply + 1) / 2);
    const isWhite = ply % 2 === 1;

    const prefix = isWhite
      ? `${moveNumber}. `
      : needsNumber
        ? `${moveNumber}... `
        : '';

    const comment = node.comment ? ` {${node.comment}}` : '';
    return `${prefix}${node.san}${comment}`;
  }

  /**
   * Eine Ebene: der erste Zug laeuft in der Hauptlinie weiter, alle weiteren
   * stehen samt ihrer eigenen Fortsetzung in Klammern dahinter.
   * @param {Node[]} level
   */
  function renderLevel(level, ply, needsNumber) {
    if (level.length === 0) return '';

    const [mainline, ...alternatives] = level;
    const parts = [renderMove(mainline, ply, needsNumber)];

    for (const alternative of alternatives) {
      const inner = [renderMove(alternative, ply, true)];
      const continuation = renderLevel(alternative.children, ply + 1, false);
      if (continuation) inner.push(continuation);
      parts.push(`(${inner.join(' ')})`);
    }

    // Nach einer eingeschobenen Variante braucht der naechste Zug wieder
    // seine Nummer, sonst laesst sich die Hauptlinie nicht mehr zuordnen.
    const rest = renderLevel(
      mainline.children,
      ply + 1,
      alternatives.length > 0,
    );
    if (rest) parts.push(rest);

    return parts.join(' ');
  }

  const body = renderLevel(roots, 1, false);
  return `${head}\n\n${body} *\n`;
}
