import { execSync } from 'node:child_process';
import { copyFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { PrismaClient } from '@prisma/client';
import type { FastifyInstance } from 'fastify';

import { buildApp } from '../src/app.js';
import { loadEnv } from '../src/env.js';
import type { LichessIdentity } from '../src/lib/lichess.js';

export interface TestContext {
  app: FastifyInstance;
  prisma: PrismaClient;
  /** Welche Identität die nächste Anmeldung bestätigt bekommt. */
  identity: LichessIdentity;
  close: () => Promise<void>;
}

/**
 * Eine leere Datenbank mit dem aktuellen Schema, einmal je Testprozess
 * angelegt und danach nur noch kopiert.
 *
 * `prisma db push` dauert Sekunden; ein Aufruf je Test wäre die längste Zeit
 * des Laufs. Kopieren einer SQLite-Datei kostet nichts.
 */
let template: string | null = null;

function schemaTemplate(): string {
  if (template !== null) return template;

  const dir = mkdtempSync(join(tmpdir(), 'masteropening-schema-'));
  const file = join(dir, 'template.db');

  // `execSync` statt `execFileSync`: unter Windows ist `npx` eine
  // Batch-Datei, die ohne Shell nicht startet.
  execSync('npx prisma db push --skip-generate --accept-data-loss', {
    env: { ...process.env, DATABASE_URL: `file:${file}` },
    stdio: 'pipe',
  });

  template = file;
  return file;
}

/** Baut den Server gegen eine frische Datenbank im Temp-Verzeichnis. */
export async function createTestApp(): Promise<TestContext> {
  const dir = mkdtempSync(join(tmpdir(), 'masteropening-'));
  const file = join(dir, 'test.db');
  const url = `file:${file}`;

  copyFileSync(schemaTemplate(), file);

  const prisma = new PrismaClient({ datasources: { db: { url } } });
  const env = loadEnv({ ...process.env, DATABASE_URL: url });

  const context: TestContext = {
    app: undefined as unknown as FastifyInstance,
    prisma,
    identity: { id: 'leon', username: 'Leon' },
    close: async () => {
      await context.app.close();
      await prisma.$disconnect();
      rmSync(dir, { recursive: true, force: true });
    },
  };

  context.app = await buildApp({
    env,
    prisma,
    verifyLichessToken: async (token) => {
      if (token === 'ungueltig') {
        const { LichessVerificationError } = await import(
          '../src/lib/lichess.js'
        );
        throw new LichessVerificationError('Lichess-Token wurde abgelehnt');
      }
      return context.identity;
    },
  });

  await context.app.ready();
  return context;
}

/** Meldet sich an und liefert die Token samt Nutzerkennung. */
export async function signIn(
  context: TestContext,
  lichessToken = 'gueltiges-token',
): Promise<{ accessToken: string; refreshToken: string; userId: string }> {
  const response = await context.app.inject({
    method: 'POST',
    url: '/v1/auth/lichess',
    payload: { lichessToken },
  });

  const body = response.json<{
    accessToken: string;
    refreshToken: string;
    user: { id: string };
  }>();

  return {
    accessToken: body.accessToken,
    refreshToken: body.refreshToken,
    userId: body.user.id,
  };
}

export function bearer(accessToken: string): Record<string, string> {
  return { authorization: `Bearer ${accessToken}` };
}

/** Ein Repertoire, wie die App es hochlädt. */
export function repertoirePayload(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    uuid: 'repertoire-0001',
    name: 'Sizilianisch',
    side: 'black',
    pgn: '[Event "?"]\n\n1. e4 c5 *',
    startFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    ecoCodes: 'B20',
    source: 'library',
    sortOrder: 0,
    isArchived: false,
    nodeCount: 2,
    lineCount: 1,
    revision: 1,
    updatedAt: '2026-07-30T10:00:00.000Z',
    ...overrides,
  };
}

export function progressPayload(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    repertoireUuid: 'repertoire-0001',
    pathHash: 'a'.repeat(40),
    state: 'review',
    stability: 4.2,
    difficulty: 5.1,
    due: '2026-08-02T10:00:00.000Z',
    lastReview: '2026-07-30T10:00:00.000Z',
    reps: 3,
    lapses: 0,
    correctCount: 3,
    wrongCount: 0,
    updatedAt: '2026-07-30T10:00:00.000Z',
    ...overrides,
  };
}
