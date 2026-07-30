import { z } from 'zod';

/**
 * Ein Zeitstempel als ISO-8601-Text.
 *
 * Bewusst von Hand geprüft statt über `z.string().datetime()`: die App
 * schickt lokale Zeitstempel mit Zonenversatz, die je nach Zod-Version durch
 * die strengere Prüfung fielen.
 */
export const isoDate = z
  .string()
  .min(1)
  .refine((value) => !Number.isNaN(Date.parse(value)), {
    message: 'kein gültiger Zeitstempel',
  });

export const authLichessBody = z.object({
  /** Das Lichess-Zugriffstoken, mit dem der Anrufer seine Identität belegt. */
  lichessToken: z.string().min(8).max(512),
});

export const refreshBody = z.object({
  refreshToken: z.string().min(16).max(512),
});

export const patchMeBody = z.object({
  username: z.string().min(1).max(64).optional(),
});

export const deviceBody = z.object({
  installationId: z.string().min(8).max(128),
  platform: z.enum(['android', 'ios', 'windows', 'macos', 'linux']),
  appVersion: z.string().max(32).optional(),
  pushToken: z.string().max(512).nullish(),
});

export const repertoirePayload = z.object({
  uuid: z.string().min(8).max(64),
  name: z.string().min(1).max(120),
  side: z.enum(['white', 'black']),
  pgn: z.string().max(1_000_000),
  startFen: z.string().min(1).max(120),
  ecoCodes: z.string().max(512).default(''),
  source: z.string().min(1).max(32),
  sourceRef: z.string().max(256).nullish(),
  sortOrder: z.number().int().default(0),
  isArchived: z.boolean().default(false),
  nodeCount: z.number().int().nonnegative().default(0),
  lineCount: z.number().int().nonnegative().default(0),
  revision: z.number().int().nonnegative().default(0),
  updatedAt: isoDate,
  deletedAt: isoDate.nullish(),
});

export const progressPayload = z.object({
  repertoireUuid: z.string().min(8).max(64),
  pathHash: z.string().length(40),
  state: z.string().min(1).max(32),
  stability: z.number(),
  difficulty: z.number(),
  due: isoDate,
  lastReview: isoDate.nullish(),
  reps: z.number().int().nonnegative(),
  lapses: z.number().int().nonnegative(),
  correctCount: z.number().int().nonnegative(),
  wrongCount: z.number().int().nonnegative(),
  updatedAt: isoDate,
});

export const profilePayload = z.object({
  totalXp: z.number().int().nonnegative(),
  streakCurrent: z.number().int().nonnegative(),
  streakBest: z.number().int().nonnegative(),
  streakFreezes: z.number().int().nonnegative(),
  lastActiveDay: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .nullish(),
  updatedAt: isoDate,
});

/**
 * Obergrenzen je Anfrage. Ein Repertoire ist ein Dokument von einigen
 * Kilobyte; wer mehr als zweihundert davon auf einmal schickt, hat entweder
 * einen Fehler oder etwas anderes vor.
 */
export const pushBody = z.object({
  repertoires: z.array(repertoirePayload).max(200).default([]),
  progress: z.array(progressPayload).max(20_000).default([]),
  profile: profilePayload.optional(),
});

export const pullQuery = z.object({
  since: isoDate.optional(),
});

export type RepertoirePayload = z.infer<typeof repertoirePayload>;
export type ProgressPayload = z.infer<typeof progressPayload>;
export type ProfilePayload = z.infer<typeof profilePayload>;
export type PushBody = z.infer<typeof pushBody>;
