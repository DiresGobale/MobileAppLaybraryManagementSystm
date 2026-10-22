const { getDb } = require('../db/connection');

const NotificationModel = {
  create({ user_id, title, message }) {
    return getDb().prepare(
      'INSERT INTO notifications (user_id, title, message, created_at, is_read) VALUES (?, ?, ?, ?, 0)',
    ).run(user_id, title, message, Date.now()).lastInsertRowid;
  },

  forUser(userId, { unreadOnly = false } = {}) {
    const where = unreadOnly ? 'user_id = ? AND is_read = 0' : 'user_id = ?';
    return getDb().prepare(
      `SELECT * FROM notifications WHERE ${where} ORDER BY created_at DESC`,
    ).all(userId);
  },

  markRead(id) {
    return getDb().prepare('UPDATE notifications SET is_read = 1 WHERE id = ?').run(id).changes;
  },

  markAllRead(userId) {
    return getDb().prepare('UPDATE notifications SET is_read = 1 WHERE user_id = ?').run(userId).changes;
  },

  countUnread(userId) {
    return getDb().prepare(
      'SELECT COUNT(*) AS n FROM notifications WHERE user_id = ? AND is_read = 0',
    ).get(userId).n;
  },

  remove(id) {
    return getDb().prepare('DELETE FROM notifications WHERE id = ?').run(id).changes;
  },
};

const ActivityLogModel = {
  create({ user_id = null, action, details = null }) {
    return getDb().prepare(
      'INSERT INTO activity_logs (user_id, action, details, created_at) VALUES (?, ?, ?, ?)',
    ).run(user_id, action, details, Date.now()).lastInsertRowid;
  },

  recent({ limit = 50, actorId = null } = {}) {
    const where = actorId === null ? '' : 'WHERE l.user_id = ?';
    const args = actorId === null ? [] : [actorId];
    return getDb().prepare(
      `SELECT l.*, u.full_name AS actor_name, u.username AS actor_username, u.role AS actor_role
         FROM activity_logs l
         LEFT JOIN users u ON u.id = l.user_id
         ${where}
         ORDER BY l.created_at DESC
         LIMIT ?`,
    ).all(...args, limit);
  },

  countToday() {
    const now = new Date();
    const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    return getDb().prepare(
      'SELECT COUNT(*) AS n FROM activity_logs WHERE created_at >= ?',
    ).get(midnight).n;
  },
};

const SettingModel = {
  get(key) {
    const row = getDb().prepare('SELECT * FROM settings WHERE setting_key = ?').get(key);
    return row ? row.setting_value : null;
  },

  set(key, value) {
    return getDb().prepare(
      'INSERT INTO settings (setting_key, setting_value) VALUES (?, ?) ' +
      'ON CONFLICT(setting_key) DO UPDATE SET setting_value = excluded.setting_value',
    ).run(key, value).changes;
  },

  all() {
    const rows = getDb().prepare('SELECT * FROM settings').all();
    const out = {};
    for (const r of rows) out[r.setting_key] = r.setting_value;
    return out;
  },

  getInt(key, defaultValue = 0) {
    const v = this.get(key);
    const n = parseInt(v || '', 10);
    return Number.isNaN(n) ? defaultValue : n;
  },

  getBool(key, defaultValue = false) {
    const v = this.get(key);
    if (v === null || v === undefined) return defaultValue;
    return v === 'true' || v === '1';
  },
};

module.exports = { NotificationModel, ActivityLogModel, SettingModel };
