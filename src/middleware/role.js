const { ROLES } = require('../config/constants');

/**
 * Returns middleware that allows the request through only if the signed-in
 * user's role is in the allowed list. Must run AFTER `requireAuth`.
 *
 *   router.post('/users', requireAuth, requireRole('admin'), handler);
 *   router.get('/loans/history', requireAuth, requireRole('admin','librarian'), handler);
 */
function requireRole(...roles) {
  return function (req, res, next) {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required', code: 'NO_TOKEN' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        error: `Forbidden — this action requires one of: ${roles.join(', ')}`,
        code: 'INSUFFICIENT_ROLE',
        required: roles,
        actual: req.user.role,
      });
    }
    next();
  };
}

// Convenience pre-built gates.
const requireAdmin = requireRole(ROLES.ADMIN);
const requireLibrarianOrAdmin = requireRole(ROLES.LIBRARIAN, ROLES.ADMIN);
const requireStaffOrAdmin = requireRole(ROLES.LIBRARIAN, ROLES.ADMIN);

/**
 * "Owner-or-staff" gate: students may read/update their own resources
 * (e.g. their own profile, their own loans); admins and librarians may
 * access any user's resource. Pass the resolver that returns the userId
 * the resource belongs to, given the request.
 *
 *   router.get('/users/:id', requireAuth, ownerOrStaff((req) => Number(req.params.id)), handler);
 */
function ownerOrStaff(resolveOwnerId) {
  return async function (req, res, next) {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required', code: 'NO_TOKEN' });
    }
    // Staff and admin bypass ownership checks.
    if (req.user.role === ROLES.ADMIN || req.user.role === ROLES.LIBRARIAN) {
      return next();
    }
    const ownerId = await resolveOwnerId(req);
    if (ownerId === undefined || ownerId === null) {
      return res.status(404).json({ error: 'Resource not found', code: 'NOT_FOUND' });
    }
    if (Number(ownerId) !== Number(req.user.id)) {
      return res.status(403).json({ error: 'You can only access your own resources', code: 'NOT_OWNER' });
    }
    next();
  };
}

module.exports = { requireRole, requireAdmin, requireLibrarianOrAdmin, requireStaffOrAdmin, ownerOrStaff };
