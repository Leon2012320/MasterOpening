import type { FastifyInstance } from 'fastify';

import { applyPush, pullChanges } from '../lib/sync.js';
import { pullQuery, pushBody } from '../schemas.js';

/**
 * Der Abgleich.
 *
 * Zwei Richtungen, bewusst getrennt: `GET` holt, was sich seit der letzten
 * Marke geändert hat, `POST` schiebt eigene Änderungen hoch und meldet
 * zurück, was der Server nicht übernommen hat. Die App bleibt dabei die
 * Quelle der Wahrheit für ihre eigenen Daten — der Server hält nur den
 * letzten bekannten Stand für das nächste Gerät bereit.
 */
export function syncRoutes(app: FastifyInstance): void {
  app.get('/sync', { preHandler: app.authenticate }, async (request, reply) => {
    const query = pullQuery.parse(request.query);
    const result = await pullChanges(
      app.prisma,
      request.user.sub,
      query.since,
    );
    return reply.send(result);
  });

  app.post(
    '/sync',
    { preHandler: app.authenticate },
    async (request, reply) => {
      const body = pushBody.parse(request.body);
      const result = await applyPush(app.prisma, request.user.sub, body);
      return reply.send(result);
    },
  );
}
