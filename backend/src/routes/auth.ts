import type { FastifyInstance } from 'fastify';

import {
  issueRefreshToken,
  revokeAllTokens,
  rotateRefreshToken,
} from '../lib/tokens.js';
import { authLichessBody, refreshBody } from '../schemas.js';

/**
 * Anmeldung über Lichess.
 *
 * Der Server prüft das mitgeschickte Lichess-Token selbst nach — auf das Wort
 * des Clients hin ein Konto anzulegen hiesse, jedem die Identität jedes
 * anderen zu überlassen. Danach arbeitet die App mit eigenen Token weiter;
 * das Lichess-Token wird nicht gespeichert.
 */
export function authRoutes(app: FastifyInstance): void {
  app.post('/lichess', async (request, reply) => {
    const { lichessToken } = authLichessBody.parse(request.body);
    const identity = await app.verifyLichessToken(lichessToken);

    const user = await app.prisma.user.upsert({
      where: { lichessId: identity.id },
      create: { lichessId: identity.id, username: identity.username },
      update: { username: identity.username, deletedAt: null },
    });

    const refreshToken = await issueRefreshToken(app.prisma, {
      userId: user.id,
      ttlDays: app.env.REFRESH_TOKEN_TTL_DAYS,
    });

    return reply.code(200).send({
      accessToken: app.jwt.sign({ sub: user.id }),
      refreshToken,
      expiresIn: app.env.ACCESS_TOKEN_TTL_SECONDS,
      user: {
        id: user.id,
        username: user.username,
        lichessId: user.lichessId,
      },
    });
  });

  app.post('/refresh', async (request, reply) => {
    const body = refreshBody.parse(request.body);

    const rotated = await rotateRefreshToken(
      app.prisma,
      body.refreshToken,
      app.env.REFRESH_TOKEN_TTL_DAYS,
    );

    const user = await app.prisma.user.findUnique({
      where: { id: rotated.userId },
    });
    if (user === null || user.deletedAt !== null) {
      return reply.code(401).send({
        error: 'invalid_refresh_token',
        message: 'Das Konto gibt es nicht mehr',
      });
    }

    return reply.send({
      accessToken: app.jwt.sign({ sub: user.id }),
      refreshToken: rotated.refreshToken,
      expiresIn: app.env.ACCESS_TOKEN_TTL_SECONDS,
    });
  });

  app.post(
    '/logout',
    { preHandler: app.authenticate },
    async (request, reply) => {
      await revokeAllTokens(app.prisma, request.user.sub);
      return reply.code(204).send();
    },
  );
}
