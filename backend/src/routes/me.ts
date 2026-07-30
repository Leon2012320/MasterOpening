import type { FastifyInstance } from 'fastify';

import { patchMeBody } from '../schemas.js';

export function meRoutes(app: FastifyInstance): void {
  app.get('/me', { preHandler: app.authenticate }, async (request, reply) => {
    const user = await app.prisma.user.findUnique({
      where: { id: request.user.sub },
      include: { _count: { select: { repertoires: true, devices: true } } },
    });

    if (user === null || user.deletedAt !== null) {
      return reply
        .code(404)
        .send({ error: 'not_found', message: 'Konto nicht gefunden' });
    }

    return reply.send({
      id: user.id,
      lichessId: user.lichessId,
      username: user.username,
      createdAt: user.createdAt.toISOString(),
      repertoires: user._count.repertoires,
      devices: user._count.devices,
    });
  });

  app.patch('/me', { preHandler: app.authenticate }, async (request, reply) => {
    const body = patchMeBody.parse(request.body);

    const user = await app.prisma.user.update({
      where: { id: request.user.sub },
      data: { username: body.username },
    });

    return reply.send({ id: user.id, username: user.username });
  });

  /**
   * Kontolöschung.
   *
   * Google Play verlangt sie, und zwar wirklich: alle Zeilen des Nutzers
   * hängen per `onDelete: Cascade` am Konto und verschwinden mit ihm. Kein
   * Aufheben „für den Fall der Fälle" — wer löscht, meint löschen.
   */
  app.delete(
    '/me',
    { preHandler: app.authenticate },
    async (request, reply) => {
      await app.prisma.user.delete({ where: { id: request.user.sub } });
      return reply.code(204).send();
    },
  );
}
