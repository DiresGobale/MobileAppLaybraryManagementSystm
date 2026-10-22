/**
 * Global Jest setup. Runs ONCE before any test suite. We force the env to
 * use a per-process in-memory DB by setting process.env.DATABASE_PATH
 * BEFORE any test file loads ../src/config/env.js.
 */
module.exports = async () => {
  // Each test file overrides this with its own fresh DB path; setting it
  // here at least prevents the file DB at ./data/iulms.db from being touched
  // if any test forgets to set its own path.
  process.env.DATABASE_PATH = `:memory:`;
  process.env.NODE_ENV = 'test';
  process.env.JWT_SECRET = 'test-secret-only-not-for-production-use';
  process.env.DISABLE_RATE_LIMIT = '1';
};
