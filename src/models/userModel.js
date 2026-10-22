const { getDb } = require('../db/connection');

/**
 * Users data-access layer. No business logic — just SQL.
 */
const UserModel = {
  findById(id) {
    return getDb().prepare('SELECT * FROM users WHERE id = ?').get(id);
  },

  findByUsername(username) {
    return getDb().prepare('SELECT * FROM users WHERE username = ? COLLATE NOCASE').get(username);
  },

  findByEmail(email) {
    return getDb().prepare('SELECT * FROM users WHERE email = ? COLLATE NOCASE').get(email);
  },

  findByStudentId(studentId) {
    return getDb().prepare('SELECT * FROM users WHERE student_id = ? COLLATE NOCASE').get(studentId);
  },

  create({ full_name, username, email, password_hash, role, student_id = null, department = null }) {
    const db = getDb();
    const now = Date.now();
    const result = db.prepare(
      `INSERT INTO users (full_name, username, email, password_hash, role, student_id, department, created_at, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)`,
    ).run(full_name, username, email, password_hash, role, student_id, department, now);
    return result.lastInsertRowid;
  },

  update(id, fields) {
    const allowed = ['full_name', 'username', 'email', 'role', 'student_id', 'department', 'is_active'];
    const sets = [];
    const args = [];
    for (const [k, v] of Object.entries(fields)) {
      if (allowed.includes(k)) {
        sets.push(`${k} = ?`);
        args.push(v);
      }
    }
    if (sets.length === 0) return 0;
    args.push(id);
    return getDb().prepare(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`).run(...args).changes;
  },

  updatePassword(id, password_hash) {
    return getDb().prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(password_hash, id).changes;
  },

  deactivate(id) {
    return getDb().prepare('UPDATE users SET is_active = 0 WHERE id = ?').run(id).changes;
  },

  reactivate(id) {
    return getDb().prepare('UPDATE users SET is_active = 1 WHERE id = ?').run(id).changes;
  },

  remove(id) {
    return getDb().prepare('DELETE FROM users WHERE id = ?').run(id).changes;
  },

  all({ roleFilter } = {}) {
    if (roleFilter) {
      return getDb().prepare('SELECT * FROM users WHERE role = ? ORDER BY created_at DESC').all(roleFilter);
    }
    return getDb().prepare('SELECT * FROM users ORDER BY created_at DESC').all();
  },

  countStudents() {
    return getDb().prepare("SELECT COUNT(*) AS n FROM users WHERE role = 'student'").get().n;
  },

  countByRole(role) {
    return getDb().prepare('SELECT COUNT(*) AS n FROM users WHERE role = ? AND is_active = 1').get(role).n;
  },

  countAll() {
    return getDb().prepare('SELECT COUNT(*) AS n FROM users').get().n;
  },
};

module.exports = UserModel;
