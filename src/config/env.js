const path = require('path');

/**
 * Centralised config loader. Reads from process.env (which dotenv populates
 * from .env on startup) and applies safe defaults so the server can run
 * even without an .env file present (development convenience).
 */
const env = process.env;

const config = {
  env: env.NODE_ENV || 'development',
  port: parseInt(env.PORT || '4000', 10),
  isProd: (env.NODE_ENV || '').toLowerCase() === 'production',

  // Database
  databasePath: env.DATABASE_PATH || path.resolve(__dirname, '../../data/iulms.db'),

  // JWT
  jwt: {
    secret: env.JWT_SECRET || 'dev-only-insecure-secret-please-set-JWT_SECRET',
    expiresIn: env.JWT_EXPIRES_IN || '7d',
    issuer: env.JWT_ISSUER || 'iulms-backend',
  },

  // CORS — split comma list, trim, drop empty entries.
  corsOrigins: (env.CORS_ALLOWED_ORIGINS || '*')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),

  // Rate limiting
  rateLimit: {
    windowMs: parseInt(env.RATE_LIMIT_WINDOW_MS || '900000', 10),
    max: parseInt(env.RATE_LIMIT_MAX || '300', 10),
  },

  // Default admin (seed-only)
  defaultAdmin: {
    fullName: env.DEFAULT_ADMIN_FULL_NAME || 'Selam Bekele',
    username: env.DEFAULT_ADMIN_USERNAME || 'admin',
    email: env.DEFAULT_ADMIN_EMAIL || 'admin@injibara.edu',
    password: env.DEFAULT_ADMIN_PASSWORD || 'ChangeMe!2025',
  },

  logLevel: env.LOG_LEVEL || 'info',
};

module.exports = config;
