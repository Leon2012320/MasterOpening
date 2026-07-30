import { createHash, randomBytes } from 'node:crypto';

import type { PrismaClient } from '@prisma/client';

/** Ein frisch ausgegebenes Tokenpaar. */
export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export class RefreshTokenError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RefreshTokenError';
  }
}

/**
 * Erneuerungs-Token liegen nur als Hash in der Datenbank.
 *
 * SHA-256 ohne Salz reicht hier, anders als bei Passwörtern: das Token ist
 * ein Zufallswert mit 256 Bit Entropie, den niemand erraten und für den
 * niemand eine Tabelle vorberechnen kann.
 */
export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

export function generateRefreshToken(): string {
  return randomBytes(32).toString('base64url');
}

export function expiryFromNow(days: number, now = new Date()): Date {
  return new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
}

/**
 * Legt ein neues Erneuerungs-Token an.
 *
 * `familyId` verbindet alle Token, die auseinander hervorgegangen sind — beim
 * ersten Anmelden beginnt eine neue Familie.
 */
export async function issueRefreshToken(
  prisma: PrismaClient,
  options: { userId: string; familyId?: string; ttlDays: number },
): Promise<string> {
  const token = generateRefreshToken();

  await prisma.refreshToken.create({
    data: {
      userId: options.userId,
      tokenHash: hashToken(token),
      familyId: options.familyId ?? randomBytes(16).toString('hex'),
      expiresAt: expiryFromNow(options.ttlDays),
    },
  });

  return token;
}

/**
 * Tauscht ein Erneuerungs-Token gegen ein neues.
 *
 * Rotation mit Wiederverwendungs-Erkennung: jedes Token gilt genau einmal.
 * Kommt ein bereits entwertetes zurück, hat es jemand kopiert — dann fällt
 * die ganze Familie, und beide Seiten müssen sich neu anmelden. Das ist
 * unbequem und genau richtig.
 */
export async function rotateRefreshToken(
  prisma: PrismaClient,
  presentedToken: string,
  ttlDays: number,
  now = new Date(),
): Promise<{ userId: string; refreshToken: string }> {
  const existing = await prisma.refreshToken.findUnique({
    where: { tokenHash: hashToken(presentedToken) },
  });

  if (!existing) {
    throw new RefreshTokenError('Unbekanntes Erneuerungs-Token');
  }

  if (existing.revokedAt !== null) {
    await prisma.refreshToken.updateMany({
      where: { familyId: existing.familyId, revokedAt: null },
      data: { revokedAt: now },
    });
    throw new RefreshTokenError('Token wurde bereits verwendet');
  }

  if (existing.expiresAt.getTime() <= now.getTime()) {
    throw new RefreshTokenError('Erneuerungs-Token ist abgelaufen');
  }

  const next = generateRefreshToken();

  await prisma.$transaction([
    prisma.refreshToken.update({
      where: { id: existing.id },
      data: { revokedAt: now },
    }),
    prisma.refreshToken.create({
      data: {
        userId: existing.userId,
        tokenHash: hashToken(next),
        familyId: existing.familyId,
        expiresAt: expiryFromNow(ttlDays, now),
      },
    }),
  ]);

  return { userId: existing.userId, refreshToken: next };
}

/** Beim Abmelden: alle offenen Token dieses Nutzers entwerten. */
export async function revokeAllTokens(
  prisma: PrismaClient,
  userId: string,
  now = new Date(),
): Promise<number> {
  const result = await prisma.refreshToken.updateMany({
    where: { userId, revokedAt: null },
    data: { revokedAt: now },
  });
  return result.count;
}
