import { z } from 'zod';

/**
 * Die Umgebung wird beim Start geprüft, nicht beim ersten Zugriff.
 *
 * Ein fehlendes Geheimnis soll den Dienst gar nicht erst hochkommen lassen —
 * schlimmer wäre ein Server, der läuft und Token mit einem leeren Schlüssel
 * signiert.
 */
const schema = z.object({
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),

  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().int().positive().default(3000),

  DATABASE_URL: z.string().min(1).default('file:./prisma/dev.db'),

  /** Signiert die Zugriffstoken. Mindestens 32 Zeichen. */
  JWT_SECRET: z.string().min(32),

  /** Wie lange ein Zugriffstoken gilt (Sekunden). */
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(900),

  /** Wie lange ein Erneuerungs-Token gilt (Tage). */
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(60),

  /** Gegen diese Instanz wird das Lichess-Token geprüft. */
  LICHESS_API_URL: z.string().url().default('https://lichess.org'),

  /** Komma-getrennt; leer heisst: keine Browser-Herkunft erlaubt. */
  CORS_ORIGINS: z.string().default(''),

  /** Anfragen je Minute und IP. */
  RATE_LIMIT_PER_MINUTE: z.coerce.number().int().positive().default(120),
});

export type Env = z.infer<typeof schema>;

export function loadEnv(source: NodeJS.ProcessEnv = process.env): Env {
  const parsed = schema.safeParse(source);

  if (!parsed.success) {
    const details = parsed.error.issues
      .map((issue) => `  ${issue.path.join('.') || '(root)'}: ${issue.message}`)
      .join('\n');
    throw new Error(`Ungültige Umgebung:\n${details}`);
  }

  return parsed.data;
}

export function corsOrigins(env: Env): string[] {
  return env.CORS_ORIGINS.split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
}
