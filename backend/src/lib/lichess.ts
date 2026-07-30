/** Die Identität, die Lichess für ein Token bestätigt. */
export interface LichessIdentity {
  id: string;
  username: string;
}

/**
 * Prüft ein Lichess-Token und liefert, wem es gehört.
 *
 * Als Funktionstyp, weil der Server ihn austauschen können muss: die Tests
 * sollen weder Lichess befragen noch ein echtes Token brauchen.
 */
export type LichessVerifier = (token: string) => Promise<LichessIdentity>;

export class LichessVerificationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'LichessVerificationError';
  }
}

/**
 * Der Normalfall: das Konto bei Lichess abfragen.
 *
 * Das Token wird nicht gespeichert. Es dient einmalig als Nachweis, dass der
 * Anrufer wirklich dieses Lichess-Konto besitzt; danach arbeitet der Server
 * mit eigenen Token weiter.
 */
export function createLichessVerifier(baseUrl: string): LichessVerifier {
  return async (token: string): Promise<LichessIdentity> => {
    const response = await fetch(`${baseUrl}/api/account`, {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/json',
      },
      signal: AbortSignal.timeout(10_000),
    });

    if (response.status === 401 || response.status === 403) {
      throw new LichessVerificationError('Lichess-Token wurde abgelehnt');
    }
    if (!response.ok) {
      throw new LichessVerificationError(
        `Lichess antwortete mit ${response.status}`,
      );
    }

    const body = (await response.json()) as {
      id?: unknown;
      username?: unknown;
    };

    if (typeof body.id !== 'string' || body.id.length === 0) {
      throw new LichessVerificationError('Antwort ohne Kontokennung');
    }

    return {
      id: body.id,
      username:
        typeof body.username === 'string' && body.username.length > 0
          ? body.username
          : body.id,
    };
  };
}
