import type { PrismaClient } from '@prisma/client';

import type {
  ProfilePayload,
  ProgressPayload,
  PushBody,
  RepertoirePayload,
} from '../schemas.js';

/** Welche Zeilen der Server übernommen hat und welche er abgelehnt hat. */
export interface PushResult {
  serverTime: string;
  applied: { repertoires: number; progress: number; profile: boolean };
  conflicts: {
    repertoires: string[];
    progress: { repertoireUuid: string; pathHash: string }[];
    profile: boolean;
  };
}

export interface PullResult {
  serverTime: string;
  repertoires: RepertoirePayload[];
  progress: ProgressPayload[];
  profile: ProfilePayload | null;
}

/**
 * Wer gewinnt, wenn beide Seiten dieselbe Zeile geändert haben.
 *
 * Der jüngere Stand gewinnt; bei gleicher Zeit die höhere Revision. Für ein
 * Repertoire, das als PGN-Dokument reist, gibt es kein sinnvolles Verschmelzen
 * — ein halb zusammengeführter Variantenbaum wäre schlimmer als der Verlust
 * einer Änderung. Der Lernstand ist unkritisch: er wächst ohnehin monoton.
 */
export function incomingWins(
  incoming: { updatedAt: Date; revision?: number },
  existing: { updatedAt: Date; revision?: number } | null,
): boolean {
  if (existing === null) return true;

  const delta = incoming.updatedAt.getTime() - existing.updatedAt.getTime();
  if (delta !== 0) return delta > 0;

  return (incoming.revision ?? 0) >= (existing.revision ?? 0);
}

function toDate(value: string | null | undefined): Date | null {
  return value === null || value === undefined ? null : new Date(value);
}

export async function applyPush(
  prisma: PrismaClient,
  userId: string,
  body: PushBody,
): Promise<PushResult> {
  const now = new Date();

  const conflicts: PushResult['conflicts'] = {
    repertoires: [],
    progress: [],
    profile: false,
  };
  let repertoiresApplied = 0;
  let progressApplied = 0;
  let profileApplied = false;

  for (const incoming of body.repertoires) {
    const existing = await prisma.repertoire.findUnique({
      where: { userId_uuid: { userId, uuid: incoming.uuid } },
      select: { updatedAt: true, revision: true },
    });

    const candidate = {
      updatedAt: new Date(incoming.updatedAt),
      revision: incoming.revision,
    };

    if (!incomingWins(candidate, existing)) {
      conflicts.repertoires.push(incoming.uuid);
      continue;
    }

    const data = {
      name: incoming.name,
      side: incoming.side,
      pgn: incoming.pgn,
      startFen: incoming.startFen,
      ecoCodes: incoming.ecoCodes,
      source: incoming.source,
      sourceRef: incoming.sourceRef ?? null,
      sortOrder: incoming.sortOrder,
      isArchived: incoming.isArchived,
      nodeCount: incoming.nodeCount,
      lineCount: incoming.lineCount,
      revision: incoming.revision,
      updatedAt: candidate.updatedAt,
      deletedAt: toDate(incoming.deletedAt),
      syncedAt: now,
    };

    await prisma.repertoire.upsert({
      where: { userId_uuid: { userId, uuid: incoming.uuid } },
      create: { userId, uuid: incoming.uuid, ...data },
      update: data,
    });
    repertoiresApplied += 1;
  }

  for (const incoming of body.progress) {
    const key = {
      userId,
      repertoireUuid: incoming.repertoireUuid,
      pathHash: incoming.pathHash,
    };

    const existing = await prisma.nodeProgress.findUnique({
      where: { userId_repertoireUuid_pathHash: key },
      select: { updatedAt: true },
    });

    const candidate = { updatedAt: new Date(incoming.updatedAt) };

    if (!incomingWins(candidate, existing)) {
      conflicts.progress.push({
        repertoireUuid: incoming.repertoireUuid,
        pathHash: incoming.pathHash,
      });
      continue;
    }

    const data = {
      state: incoming.state,
      stability: incoming.stability,
      difficulty: incoming.difficulty,
      due: new Date(incoming.due),
      lastReview: toDate(incoming.lastReview),
      reps: incoming.reps,
      lapses: incoming.lapses,
      correctCount: incoming.correctCount,
      wrongCount: incoming.wrongCount,
      updatedAt: candidate.updatedAt,
      syncedAt: now,
    };

    await prisma.nodeProgress.upsert({
      where: { userId_repertoireUuid_pathHash: key },
      create: { ...key, ...data },
      update: data,
    });
    progressApplied += 1;
  }

  if (body.profile) {
    const existing = await prisma.profile.findUnique({
      where: { userId },
      select: { updatedAt: true },
    });
    const candidate = { updatedAt: new Date(body.profile.updatedAt) };

    if (incomingWins(candidate, existing)) {
      const data = {
        totalXp: body.profile.totalXp,
        streakCurrent: body.profile.streakCurrent,
        streakBest: body.profile.streakBest,
        streakFreezes: body.profile.streakFreezes,
        lastActiveDay: body.profile.lastActiveDay ?? null,
        updatedAt: candidate.updatedAt,
        syncedAt: now,
      };

      await prisma.profile.upsert({
        where: { userId },
        create: { userId, ...data },
        update: data,
      });
      profileApplied = true;
    } else {
      conflicts.profile = true;
    }
  }

  return {
    serverTime: now.toISOString(),
    applied: {
      repertoires: repertoiresApplied,
      progress: progressApplied,
      profile: profileApplied,
    },
    conflicts,
  };
}

/**
 * Was sich seit [since] geändert hat.
 *
 * Gefiltert wird über `syncedAt`, die Uhr des Servers. Über `updatedAt` ginge
 * es nicht: die Uhr eines fremden Geräts kann nachgehen, und dann käme eine
 * gerade hochgeladene Änderung beim nächsten Abholen nicht mit.
 */
export async function pullChanges(
  prisma: PrismaClient,
  userId: string,
  since?: string,
): Promise<PullResult> {
  const now = new Date();
  const after = since === undefined ? undefined : new Date(since);
  const window = after === undefined ? {} : { syncedAt: { gt: after } };

  const [repertoires, progress, profile] = await Promise.all([
    prisma.repertoire.findMany({ where: { userId, ...window } }),
    prisma.nodeProgress.findMany({ where: { userId, ...window } }),
    prisma.profile.findUnique({ where: { userId } }),
  ]);

  return {
    serverTime: now.toISOString(),
    repertoires: repertoires.map((row) => ({
      uuid: row.uuid,
      name: row.name,
      side: row.side as 'white' | 'black',
      pgn: row.pgn,
      startFen: row.startFen,
      ecoCodes: row.ecoCodes,
      source: row.source,
      sourceRef: row.sourceRef,
      sortOrder: row.sortOrder,
      isArchived: row.isArchived,
      nodeCount: row.nodeCount,
      lineCount: row.lineCount,
      revision: row.revision,
      updatedAt: row.updatedAt.toISOString(),
      deletedAt: row.deletedAt?.toISOString() ?? null,
    })),
    progress: progress.map((row) => ({
      repertoireUuid: row.repertoireUuid,
      pathHash: row.pathHash,
      state: row.state,
      stability: row.stability,
      difficulty: row.difficulty,
      due: row.due.toISOString(),
      lastReview: row.lastReview?.toISOString() ?? null,
      reps: row.reps,
      lapses: row.lapses,
      correctCount: row.correctCount,
      wrongCount: row.wrongCount,
      updatedAt: row.updatedAt.toISOString(),
    })),
    profile:
      profile === null || (after !== undefined && profile.syncedAt <= after)
        ? null
        : {
            totalXp: profile.totalXp,
            streakCurrent: profile.streakCurrent,
            streakBest: profile.streakBest,
            streakFreezes: profile.streakFreezes,
            lastActiveDay: profile.lastActiveDay,
            updatedAt: profile.updatedAt.toISOString(),
          },
  };
}
