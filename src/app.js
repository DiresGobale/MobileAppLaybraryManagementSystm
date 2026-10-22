const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const config = require('./config/env');
const routes = require('./routes');
const { notFound, errorHandler } = require('./middleware/errorHandler');

/**
 * Builds the Express application. Exposed as a function so tests can mount
 * the same app on a different port without re-loading modules.
 */
function createApp() {
  const app = express();

  // --- Security ---
  app.use(helmet());
  app.use(cors({
    origin: (origin, cb) => {
      // Allow any of the configured origins, and allow curl/Postman (no Origin header).
      if (!origin) return cb(null, true);
      const allowed = config.corsOrigins;
      if (allowed.includes('*') || allowed.includes(origin)) {
        cb(null, true);
      } else {
        cb(new Error(`CORS: origin ${origin} not allowed`));
      }
    },
    credentials: true,
  }));

  // --- Body parsing ---
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true, limit: '1mb' }));

  // --- Compression + logging ---
  app.use(compression());
  app.use(morgan(config.isProd ? 'combined' : 'dev'));

  // --- Rate limiting (only in prod to keep tests fast) ---
  if (config.isProd) {
    app.use(rateLimit({
      windowMs: config.rateLimit.windowMs,
      max: config.rateLimit.max,
      standardHeaders: true,
      legacyHeaders: false,
    }));
  }

  // --- Routes ---
  app.use(routes);

  // --- 404 + error handler (last middleware) ---
  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
