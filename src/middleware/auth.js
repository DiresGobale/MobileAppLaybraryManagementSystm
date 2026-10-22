const { verifyToken } = require('../utils/jwt');

/**
 * Attaches `req.user = { id, role, username }` if a valid Bearer JWT is
 * present in the Authorization header. Anonymous routes (login, register,
 * public landing page content) don't use this middleware.
 *
 * On failure, responds 401 with a short reason.
 */
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    return res.status(401).json({ error: 'Authentication required', code: 'NO_TOKEN' });
  }
  try {
    const payload = verifyToken(match[1]);
    req.user = { id: payload.sub, role: payload.role, username: payload.username };
    next();
  } catch (err) {
    const code = err.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'INVALID_TOKEN';
    return res.status(401).json({ error: err.message, code });
  }
}

module.exports = requireAuth;
