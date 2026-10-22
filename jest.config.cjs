/** @type {import('jest').Config} */
module.exports = {
  testEnvironment: 'node',
  setupFiles: ['<rootDir>/tests/jest.setup.cjs'],
  testMatch: ['**/tests/**/*.test.js'],
  testTimeout: 10000,
  verbose: true,
  forceExit: true,
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/db/seed.js',
    '!src/db/migrate.js',
  ],
};
