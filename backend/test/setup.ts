// Feste Umgebung für alle Testdateien. `loadEnv` prüft streng — ohne diese
// Werte käme keine App hoch.
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-geheimnis-mit-mehr-als-zweiunddreissig-zeichen';
process.env.LICHESS_API_URL = 'https://lichess.invalid';
process.env.RATE_LIMIT_PER_MINUTE = '10000';
