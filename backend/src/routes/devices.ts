import type { FastifyInstance } from 'fastify';

import { deviceBody } from '../schemas.js';

/**
 * Geräteverwaltung.
 *
 * Der Push-Token wird entgegengenommen und aufbewahrt, aber noch nicht
 * benutzt: Erinnerungen laufen als lokale Benachrichtigungen, solange die App
 * ohne Firebase auskommt. Die Zeile jetzt anzulegen kostet nichts und erspart
 * später eine Wanderung des Schemas.
 */
export function deviceRoutes(app: FastifyInstance): void {
  app.post(
    '/devices',
    { preHandler: app.authenticate },
    async (request, reply) => {
      const body = deviceBody.parse(request.body);
      const userId = request.user.sub;

      const data = {
        platform: body.platform,
        appVersion: body.appVersion ?? null,
        pushToken: body.pushToken ?? null,
        lastSeenAt: new Date(),
      };

      const device = await app.prisma.device.upsert({
        where: {
          userId_installationId: { userId, installationId: body.installationId },
        },
        create: { userId, installationId: body.installationId, ...data },
        update: data,
      });

      return reply.send({
        id: device.id,
        installationId: device.installationId,
        platform: device.platform,
      });
    },
  );

  app.get(
    '/devices',
    { preHandler: app.authenticate },
    async (request, reply) => {
      const devices = await app.prisma.device.findMany({
        where: { userId: request.user.sub },
        orderBy: { lastSeenAt: 'desc' },
      });

      return reply.send(
        devices.map((device) => ({
          id: device.id,
          installationId: device.installationId,
          platform: device.platform,
          appVersion: device.appVersion,
          lastSeenAt: device.lastSeenAt.toISOString(),
        })),
      );
    },
  );

  app.delete(
    '/devices/:id',
    { preHandler: app.authenticate },
    async (request, reply) => {
      const { id } = request.params as { id: string };

      const result = await app.prisma.device.deleteMany({
        where: { id, userId: request.user.sub },
      });

      if (result.count === 0) {
        return reply
          .code(404)
          .send({ error: 'not_found', message: 'Gerät nicht gefunden' });
      }
      return reply.code(204).send();
    },
  );
}
