import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';
import { PrismaClient } from '@prisma/client';
import Fastify, {
  type FastifyError,
  type FastifyInstance,
  type FastifyReply,
  type FastifyRequest,
} from 'fastify';
import { ZodError } from 'zod';

import { corsOrigins, loadEnv, type Env } from './env.js';
import {
  createLichessVerifier,
  LichessVerificationError,
  type LichessVerifier,
} from './lib/lichess.js';
import { RefreshTokenError } from './lib/tokens.js';
import { authRoutes } from './routes/auth.js';
import { deviceRoutes } from './routes/devices.js';
import { healthRoutes } from './routes/health.js';
import { meRoutes } from './routes/me.js';
import { syncRoutes } from './routes/sync.js';

declare module 'fastify' {
  interface FastifyInstance {
    prisma: PrismaClient;
    env: Env;
    verifyLichessToken: LichessVerifier;
    /** Weist Anfragen ohne gültiges Zugriffstoken ab. */
    authenticate: (
      request: FastifyRequest,
      reply: FastifyReply,
    ) => Promise<void>;
  }
}

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: { sub: string };
    user: { sub: string };
  }
}

export interface BuildOptions {
  env?: Env;
  prisma?: PrismaClient;
  /** Im Test durch eine Fassung ohne Netz ersetzt. */
  verifyLichessToken?: LichessVerifier;
}

export async function buildApp(
  options: BuildOptions = {},
): Promise<FastifyInstance> {
  const env = options.env ?? loadEnv();
  const prisma = options.prisma ?? new PrismaClient();

  const app = Fastify({
    logger:
      env.NODE_ENV === 'test'
        ? false
        : {
            level: env.NODE_ENV === 'production' ? 'info' : 'debug',
            // Kopfzeilen können Token tragen — die gehören nicht ins Protokoll.
            redact: ['req.headers.authorization', 'req.headers.cookie'],
          },
    // Ein Repertoire als PGN kann groß werden; ein Abgleich mit mehreren
    // dagegen soll nicht unbegrenzt Speicher belegen.
    bodyLimit: 8 * 1024 * 1024,
    trustProxy: true,
  });

  app.decorate('prisma', prisma);
  app.decorate('env', env);
  app.decorate(
    'verifyLichessToken',
    options.verifyLichessToken ?? createLichessVerifier(env.LICHESS_API_URL),
  );

  await app.register(helmet, {
    // Es gibt keine Seite auszuliefern, nur JSON.
    contentSecurityPolicy: false,
  });

  const origins = corsOrigins(env);
  await app.register(cors, {
    origin: origins.length === 0 ? false : origins,
    credentials: false,
  });

  await app.register(rateLimit, {
    max: env.RATE_LIMIT_PER_MINUTE,
    timeWindow: '1 minute',
  });

  await app.register(jwt, {
    secret: env.JWT_SECRET,
    sign: { expiresIn: env.ACCESS_TOKEN_TTL_SECONDS },
  });

  app.decorate('authenticate', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      await reply.code(401).send({
        error: 'unauthorized',
        message: 'Zugriffstoken fehlt oder ist ungültig',
      });
    }
  });

  app.setErrorHandler((error: FastifyError, request, reply) => {
    if (error instanceof ZodError) {
      return reply.code(400).send({
        error: 'invalid_request',
        message: 'Die Anfrage passt nicht zum erwarteten Format',
        issues: error.issues.map((issue) => ({
          path: issue.path.join('.'),
          message: issue.message,
        })),
      });
    }

    if (error instanceof LichessVerificationError) {
      return reply
        .code(401)
        .send({ error: 'lichess_rejected', message: error.message });
    }

    if (error instanceof RefreshTokenError) {
      return reply
        .code(401)
        .send({ error: 'invalid_refresh_token', message: error.message });
    }

    if (typeof error.statusCode === 'number' && error.statusCode < 500) {
      return reply
        .code(error.statusCode)
        .send({ error: error.code ?? 'request_failed', message: error.message });
    }

    request.log.error({ err: error }, 'Unbehandelter Fehler');
    return reply.code(500).send({
      error: 'internal_error',
      message: 'Da ist auf dem Server etwas schiefgegangen',
    });
  });

  await app.register(healthRoutes);
  await app.register(authRoutes, { prefix: '/v1/auth' });
  await app.register(meRoutes, { prefix: '/v1' });
  await app.register(syncRoutes, { prefix: '/v1' });
  await app.register(deviceRoutes, { prefix: '/v1' });

  app.addHook('onClose', async () => {
    if (options.prisma === undefined) await prisma.$disconnect();
  });

  return app;
}
