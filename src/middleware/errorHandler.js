/**
 * Centralised error handler. Mounted last in the Express middleware chain.
 *
 * - Express-validator errors → 400 (already handled by `validate` middleware)
 * - Custom AppError subclasses → their .status code + .message
 * - SQLite constraint violations → 409 with the constraint name
 * - Anything else → 500 with the message in dev, generic in prod
 */
function notFound(req, res) {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}`, code: 'NOT_FOUND' });
}

function errorHandler(err, req, res, _next) {
  const status = err.status || err.statusCode || 500;
  const code = err.code || (status >= 500 ? 'INTERNAL' : 'BAD_REQUEST');

  // SQLite unique constraint
  if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
    return res.status(409).json({
      error: 'A record with that unique value already exists',
      code: 'DUPLICATE',
      constraint: err.message,
    });
  }
  // SQLite FK violation
  if (err.code === 'SQLITE_CONSTRAINT_FOREIGNKEY') {
    return res.status(409).json({
      error: 'Referenced record does not exist or is in use',
      code: 'FK_VIOLATION',
      detail: err.message,
    });
  }
  // SQLite CHECK violation
  if (err.code === 'SQLITE_CONSTRAINT_CHECK') {
    return res.status(400).json({
      error: 'Constraint check failed',
      code: 'CHECK_VIOLATION',
      detail: err.message,
    });
  }

  // Always log server errors for debugging.
  if (status >= 500) {
    console.error('[error]', err);
  }

  res.status(status).json({
    error: err.message,
    code,
    ...(process.env.NODE_ENV !== 'production' && err.stack ? { stack: err.stack.split('\n') } : {}),
  });
}

/**
 * Tiny helper for throwing typed errors from controllers/services.
 *   throw new AppError('Book not found', 404, 'NOT_FOUND');
 */
class AppError extends Error {
  constructor(message, status = 500, code = 'INTERNAL') {
    super(message);
    this.status = status;
    this.code = code;
    Error.captureStackTrace(this, AppError);
  }
}

module.exports = { notFound, errorHandler, AppError };
