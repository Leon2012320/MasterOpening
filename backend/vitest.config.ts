import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: false,
    include: ['test/**/*.test.ts'],
    setupFiles: ['test/setup.ts'],
    // Jede Datei bekommt ihre eigene SQLite-Datei; parallele Läufe würden
    // sich sonst beim Anlegen des Schemas in die Quere kommen.
    fileParallelism: false,
    testTimeout: 20_000,
    hookTimeout: 60_000,
  },
});
