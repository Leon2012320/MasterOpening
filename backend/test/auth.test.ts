import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { bearer, createTestApp, signIn, type TestContext } from './helpers.js';

let context: TestContext;

beforeEach(async () => {
  context = await createTestApp();
});

afterEach(async () => {
  await context.close();
});

describe('Anmeldung über Lichess', () => {
  it('legt beim ersten Mal ein Konto an', async () => {
    const response = await context.app.inject({
      method: 'POST',
      url: '/v1/auth/lichess',
      payload: { lichessToken: 'gueltiges-token' },
    });

    expect(response.statusCode).toBe(200);
    const body = response.json<{
      accessToken: string;
      refreshToken: string;
      user: { lichessId: string; username: string };
    }>();

    expect(body.accessToken).toBeTruthy();
    expect(body.refreshToken).toBeTruthy();
    expect(body.user.lichessId).toBe('leon');
    expect(await context.prisma.user.count()).toBe(1);
  });

  it('erkennt dasselbe Lichess-Konto wieder, statt ein zweites anzulegen', async () => {
    await signIn(context);
    context.identity = { id: 'leon', username: 'LeonNeu' };
    await signIn(context);

    expect(await context.prisma.user.count()).toBe(1);
    const user = await context.prisma.user.findUniqueOrThrow({
      where: { lichessId: 'leon' },
    });
    expect(user.username).toBe('LeonNeu');
  });

  it('weist ein Token ab, das Lichess nicht kennt', async () => {
    const response = await context.app.inject({
      method: 'POST',
      url: '/v1/auth/lichess',
      payload: { lichessToken: 'ungueltig' },
    });

    expect(response.statusCode).toBe(401);
    expect(await context.prisma.user.count()).toBe(0);
  });

  it('lehnt eine Anfrage ohne Token als fehlerhaft ab', async () => {
    const response = await context.app.inject({
      method: 'POST',
      url: '/v1/auth/lichess',
      payload: {},
    });

    expect(response.statusCode).toBe(400);
    expect((response.json<{ error: string }>()).error).toBe(
      'invalid_request',
    );
  });
});

describe('Erneuerung', () => {
  it('gibt ein neues Paar aus und entwertet das alte Token', async () => {
    const first = await signIn(context);

    const response = await context.app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: first.refreshToken },
    });

    expect(response.statusCode).toBe(200);
    const body = response.json<{ refreshToken: string }>();
    expect(body.refreshToken).not.toBe(first.refreshToken);

    const reuse = await context.app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: first.refreshToken },
    });
    expect(reuse.statusCode).toBe(401);
  });

  it('entwertet die ganze Familie, wenn ein Token wiederverwendet wird', async () => {
    const first = await signIn(context);

    const second = (
      await context.app.inject({
        method: 'POST',
        url: '/v1/auth/refresh',
        payload: { refreshToken: first.refreshToken },
      })
    ).json<{ refreshToken: string }>();

    // Der Dieb versucht das alte Token — das verrät ihn.
    await context.app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: first.refreshToken },
    });

    // Danach ist auch das ehrliche Gerät ausgesperrt: unbequem, aber sicher.
    const honest = await context.app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: second.refreshToken },
    });
    expect(honest.statusCode).toBe(401);
  });

  it('kennt ein erfundenes Token nicht', async () => {
    const response = await context.app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: 'x'.repeat(43) },
    });

    expect(response.statusCode).toBe(401);
  });
});

describe('Konto', () => {
  it('liefert das eigene Profil', async () => {
    const session = await signIn(context);

    const response = await context.app.inject({
      method: 'GET',
      url: '/v1/me',
      headers: bearer(session.accessToken),
    });

    expect(response.statusCode).toBe(200);
    expect((response.json<{ username: string }>()).username).toBe('Leon');
  });

  it('verlangt ein Zugriffstoken', async () => {
    const response = await context.app.inject({ method: 'GET', url: '/v1/me' });
    expect(response.statusCode).toBe(401);
  });

  it('löscht das Konto mitsamt allen Daten', async () => {
    const session = await signIn(context);

    await context.app.inject({
      method: 'POST',
      url: '/v1/devices',
      headers: bearer(session.accessToken),
      payload: { installationId: 'geraet-0001', platform: 'android' },
    });

    const response = await context.app.inject({
      method: 'DELETE',
      url: '/v1/me',
      headers: bearer(session.accessToken),
    });

    expect(response.statusCode).toBe(204);
    expect(await context.prisma.user.count()).toBe(0);
    expect(await context.prisma.device.count()).toBe(0);
    expect(await context.prisma.refreshToken.count()).toBe(0);
  });

  it('das Erneuerungs-Token eines gelöschten Kontos gilt nicht mehr', async () => {
    const session = await signIn(context);
    await context.app.inject({
      method: 'DELETE',
      url: '/v1/me',
      headers: bearer(session.accessToken),
    });

    const response = await context.app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: session.refreshToken },
    });
    expect(response.statusCode).toBe(401);
  });
});

describe('Lebenszeichen', () => {
  it('meldet sich mit Datenbank', async () => {
    const response = await context.app.inject({
      method: 'GET',
      url: '/health',
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({ status: 'ok', database: true });
  });
});
