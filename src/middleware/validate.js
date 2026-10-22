const { validationResult } = require('express-validator');

/**
 * Wraps express-validator's validation result. If validation failed,
 * responds 400 with the list of field errors. Otherwise calls next().
 *
 * Usage:
 *   router.post('/x', [body('name').notEmpty()], validate, handler);
 */
function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array().map((e) => ({ field: e.path, message: e.msg })),
    });
  }
  next();
}

module.exports = validate;
