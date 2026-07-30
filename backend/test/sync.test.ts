import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { incomingWins } from '../src/lib/sync.js';
import {
  bearer,
  createTestApp,
  progressPayload,
  repertoirePayload,
  signIn,
  type TestContext,
} from './helpers.js';

let context: TestContext;
let session: { accessToken: string; userId: string };

beforeEach(async () => {
  context = await createTestApp();
  session = await signIn(context);
});

afterEach(async () => {
  await context.close();
});

async function push(payload: unknown) {
  return context.app.inject({
    method: 'POST',
    url: '/v1/sync',
    headers: bearer(session.accessToken),
    payload: payload as Record<string, unknown>,
  });
}

async function pull(since?: string) {
  return context.app.inject({
    method: 'GET',
    url: since === undefined ? '/v1/sync' : `/v1/sync?since=${since}`,
    headers: bearer(session.accessToken),
  });
}

describe('Konfliktregel', () => {
  it('der jüngere Stand gewinnt', () => {
    const older = { updatedAt: new Date('2026-07-01') };
    const newer = { updatedAt: new Date('2026-07-02') };

    expect(incomingWins(newer, older)).toBe(true);
    expect(incomingWins(older, newer)).toBe(false);
  });

  it('bei gleicher Zeit entscheidet die Revision', () => {
    const at = new Date('2026-07-01');

    expect(
      incomingWins({ updatedAt: at, revision: 5 }, { updatedAt: at, revision: 4 }),
    ).toBe(true);
    expect(
      incomingWins({ updatedAt: at, revision: 3 }, { updatedAt: at, revision: 4 }),
    ).toBe(false);
  });

  it('eine unbekannte Zeile wird immer angenommen', () => {
    expect(incomingWins({ updatedAt: new Date() }, null)).toBe(true);
  });
});

describe('Hochladen', () => {
  it('nimmt Repertoire, Lernstand und Spielerstand an', async () => {
    const response = await push({
      repertoires: [repertoirePayload()],
      progress: [progressPayload()],
      profile: {
        totalXp: 1200,
        streakCurrent: 4,
        streakBest: 9,
        streakFreezes: 1,
        lastActiveDay: '2026-07-30',
        updatedAt: '2026-07-30T10:00:00.000Z',
      },
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      applied: { repertoires: 1, progress: 1, profile: true },
    });

    expect(await context.prisma.repertoire.count()).toBe(1);
    expect(await context.prisma.nodeProgress.count()).toBe(1);
  });

  it('überschreibt mit einem jüngeren Stand', async () => {
    await push({ repertoires: [repertoirePayload()] });
    await push({
      repertoires: [
        repertoirePayload({
          name: 'Sizilianisch Najdorf',
          revision: 2,
          updatedAt: '2026-07-31T10:00:00.000Z',
        }),
      ],
    });

    const row = await context.prisma.repertoire.findFirstOrThrow();
    expect(row.name).toBe('Sizilianisch Najdorf');
    expect(await context.prisma.repertoire.count()).toBe(1);
  });

  it('meldet einen älteren Stand als Konflikt, statt ihn zu übernehmen', async () => {
    await push({
      repertoires: [
        repertoirePayload({
          name: 'neu',
          updatedAt: '2026-07-31T10:00:00.000Z',
        }),
      ],
    });

    const response = await push({
      repertoires: [
        repertoirePayload({
          name: 'alt',
          updatedAt: '2026-07-29T10:00:00.000Z',
        }),
      ],
    });

    expect(response.json()).toMatchObject({
      applied: { repertoires: 0 },
      conflicts: { repertoires: ['repertoire-0001'] },
    });

    const row = await context.prisma.repertoire.findFirstOrThrow();
    expect(row.name).toBe('neu');
  });

  it('behält ein gelöschtes Repertoire als Grabstein', async () => {
    await push({ repertoires: [repertoirePayload()] });
    await push({
      repertoires: [
        repertoirePayload({
          revision: 2,
          updatedAt: '2026-07-31T10:00:00.000Z',
          deletedAt: '2026-07-31T10:00:00.000Z',
        }),
      ],
    });

    const row = await context.prisma.repertoire.findFirstOrThrow();
    expect(row.deletedAt).not.toBeNull();
  });

  it('weist eine zu große Ladung ab', async () => {
    const response = await push({
      repertoires: Array.from({ length: 201 }, (_, index) =>
        repertoirePayload({ uuid: `repertoire-${index}` }),
      ),
    });

    expect(response.statusCode).toBe(400);
  });

  it('weist einen unbrauchbaren Lernstand ab', async () => {
    const response = await push({
      progress: [progressPayload({ pathHash: 'zu-kurz' })],
    });

    expect(response.statusCode).toBe(400);
  });
});

describe('Abholen', () => {
  it('liefert ohne Marke alles', async () => {
    await push({
      repertoires: [repertoirePayload()],
      progress: [progressPayload()],
    });

    const response = await pull();
    const body = response.json<{
      repertoires: unknown[];
      progress: unknown[];
      serverTime: string;
    }>();

    expect(body.repertoires).toHaveLength(1);
    expect(body.progress).toHaveLength(1);
    expect(Date.parse(body.serverTime)).not.toBeNaN();
  });

  it('liefert mit Marke nur, was seitdem dazukam', async () => {
    await push({ repertoires: [repertoirePayload()] });

    const mark = (await pull()).json<{ serverTime: string }>();

    const empty = (await pull(mark.serverTime)).json<{
      repertoires: unknown[];
    }>();
    expect(empty.repertoires).toHaveLength(0);

    await push({
      repertoires: [
        repertoirePayload({
          uuid: 'repertoire-0002',
          name: 'Englisch',
          side: 'white',
        }),
      ],
    });

    const after = (await pull(mark.serverTime)).json<{
      repertoires: { uuid: string }[];
    }>();
    expect(after.repertoires.map((r) => r.uuid)).toEqual(['repertoire-0002']);
  });

  it('gibt die Daten unverändert zurück', async () => {
    const sent = repertoirePayload();
    await push({ repertoires: [sent] });

    const body = (await pull()).json<{
      repertoires: Record<string, unknown>[];
    }>();

    expect(body.repertoires[0]).toMatchObject({
      uuid: sent.uuid,
      name: sent.name,
      side: sent.side,
      pgn: sent.pgn,
      updatedAt: sent.updatedAt,
    });
  });

  it('zeigt keine Daten eines anderen Kontos', async () => {
    await push({ repertoires: [repertoirePayload()] });

    context.identity = { id: 'jemand-anderes', username: 'Fremd' };
    const other = await signIn(context, 'anderes-token');

    const response = await context.app.inject({
      method: 'GET',
      url: '/v1/sync',
      headers: bearer(other.accessToken),
    });

    expect((response.json<{ repertoires: unknown[] }>()).repertoires).toEqual(
      [],
    );
  });

  it('verlangt eine Anmeldung', async () => {
    const response = await context.app.inject({
      method: 'GET',
      url: '/v1/sync',
    });
    expect(response.statusCode).toBe(401);
  });
});
