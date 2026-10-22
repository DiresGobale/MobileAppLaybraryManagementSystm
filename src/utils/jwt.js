const jwt = require('jsonwebtoken');
const config = require('../config/env');

/**
 * Signs a JWT for the given user object. The payload contains only the
 * minimum needed by middleware: id, role, username.
 */
function signToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      role: user.role,
      username: user.username,
    },
    config.jwt.secret,
    {
      expiresIn: config.jwt.expiresIn,
      issuer: config.jwt.issuer,
    },
  );
}

/**
 * Verifies a JWT and returns the decoded payload. Throws jwt.JsonWebTokenError
 * or jwt.TokenExpiredError on failure — the caller (auth middleware) catches
 * these and converts them to 401 responses.
 */
function verifyToken(token) {
  return jwt.verify(token, config.jwt.secret, { issuer: config.jwt.issuer });
}

module.exports = { signToken, verifyToken };
