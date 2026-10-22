const { getDb } = require('../db/connection');

const LibraryServiceModel = {
  all({ activeOnly = true } = {}) {
    const where = activeOnly ? 'WHERE is_active = 1' : '';
    return getDb().prepare(
      `SELECT * FROM library_services ${where} ORDER BY display_order ASC, id ASC`,
    ).all();
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM library_services WHERE id = ?').get(id);
  },

  create({ title, description, icon_name = 'menu_book', display_order = 0 }) {
    return getDb().prepare(
      `INSERT INTO library_services (title, description, icon_name, display_order, is_active)
       VALUES (?, ?, ?, ?, 1)`,
    ).run(title, description, icon_name, display_order).lastInsertRowid;
  },

  update(id, { title, description, icon_name, display_order, is_active }) {
    return getDb().prepare(
      `UPDATE library_services
          SET title = ?, description = ?, icon_name = ?, display_order = ?, is_active = ?
        WHERE id = ?`,
    ).run(title, description, icon_name, display_order, is_active ? 1 : 0, id).changes;
  },

  remove(id) {
    return getDb().prepare('DELETE FROM library_services WHERE id = ?').run(id).changes;
  },
};

const LibraryStepModel = {
  all({ activeOnly = true } = {}) {
    const where = activeOnly ? 'WHERE is_active = 1' : '';
    return getDb().prepare(
      `SELECT * FROM library_steps ${where} ORDER BY display_order ASC, id ASC`,
    ).all();
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM library_steps WHERE id = ?').get(id);
  },

  create({ step_number, title, description, icon_name = 'search', display_order = 0 }) {
    return getDb().prepare(
      `INSERT INTO library_steps (step_number, title, description, icon_name, display_order, is_active)
       VALUES (?, ?, ?, ?, ?, 1)`,
    ).run(step_number, title, description, icon_name, display_order).lastInsertRowid;
  },

  update(id, { step_number, title, description, icon_name, display_order, is_active }) {
    return getDb().prepare(
      `UPDATE library_steps
          SET step_number = ?, title = ?, description = ?, icon_name = ?, display_order = ?, is_active = ?
        WHERE id = ?`,
    ).run(step_number, title, description, icon_name, display_order, is_active ? 1 : 0, id).changes;
  },

  remove(id) {
    return getDb().prepare('DELETE FROM library_steps WHERE id = ?').run(id).changes;
  },
};

const ContactMessageModel = {
  create({ name, email, subject, message }) {
    return getDb().prepare(
      `INSERT INTO contact_messages (name, email, subject, message, submitted_at, is_handled)
       VALUES (?, ?, ?, ?, ?, 0)`,
    ).run(name, email, subject, message, Date.now()).lastInsertRowid;
  },

  all({ unhandledOnly = false } = {}) {
    const where = unhandledOnly ? 'WHERE is_handled = 0' : '';
    return getDb().prepare(
      `SELECT * FROM contact_messages ${where} ORDER BY submitted_at DESC`,
    ).all();
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM contact_messages WHERE id = ?').get(id);
  },

  markHandled(id) {
    return getDb().prepare('UPDATE contact_messages SET is_handled = 1 WHERE id = ?').run(id).changes;
  },

  remove(id) {
    return getDb().prepare('DELETE FROM contact_messages WHERE id = ?').run(id).changes;
  },
};

module.exports = { LibraryServiceModel, LibraryStepModel, ContactMessageModel };
