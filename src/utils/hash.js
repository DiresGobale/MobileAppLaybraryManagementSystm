const bcrypt = require('bcryptjs');

const SALT_ROUNDS = 10;

/** Hashes a plain-text password. Returns a single combined string that
 *  includes the salt (bcrypt format: `$2a$10$<22-char-salt><31-char-hash>`).
 */
function hashPassword(plain) {
  return bcrypt.hashSync(plain, SALT_ROUNDS);
}

/** Verifies a plain-text password against a bcrypt hash. */
function verifyPassword(plain, hash) {
  try {
    return bcrypt.compareSync(plain, hash);
  } catch (_) {
    return false;
  }
}

module.exports = { hashPassword, verifyPassword };
