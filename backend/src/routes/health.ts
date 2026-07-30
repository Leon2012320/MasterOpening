import type { FastifyInstance } from 'fastify';

/**
 * Lebenszeichen für Betrieb und Container-Prüfung.
 *
 * Fragt bewusst auch die Datenbank an: ein Prozess, der läuft, aber nicht an
 * seine Daten kommt, ist für den Aufrufer genauso kaputt wie einer, der steht.
 */
export function healthRoutes(app: FastifyInstance): void {
  app.get('/health', { config: { rateLimit: false } }, async (_request, reply) => {
    try {
      await app.prisma.$queryRaw`SELECT 1`;
    } catch {
      return reply.code(503).send({ status: 'degraded', database: false });
    }

    return reply.send({
      status: 'ok',
      database: true,
      time: new Date().toISOString(),
    });
  });
}
