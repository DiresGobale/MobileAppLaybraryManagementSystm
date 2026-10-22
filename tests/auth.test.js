const request = require('supertest');
const path = require('path');
const fs = require('fs');

// Reset cached modules so env.js re-reads process.env after we override it.
function freshModules(dbPath) {
  delete require.cache[require.resolve('../src/config/env')];
  delete require.cache[require.resolve('../src/db/connection')];
  delete require.cache[require.resolve('../src/app')];
  process.env.DATABASE_PATH = dbPath;
  // Clean any stale file from a previous run.
  try { if (dbPath !== ':memory:' && fs.existsSync(dbPath)) fs.unlinkSync(dbPath); } catch (_) {}
  return {
    app: require('../src/app').createApp(),
    db: require('../src/db/connection').getDb(),
  };
}

const { hashPassword } = require('../src/utils/hash');
const { signToken } = require('../src/utils/jwt');
const { ROLES } = require('../src/config/constants');

let app;
let db;
let adminToken;
let studentToken;
let bookId;

beforeAll(() => {
  // Use a fresh file-path DB so the cache reset takes effect cleanly.
  const dbPath = path.join(__dirname, '..', 'data', `test-${process.pid}-${Date.now()}.db`);
  const fresh = freshModules(dbPath);
  app = fresh.app;
  db = fresh.db;
  // Seed an admin + a student for the tests.
  const adminId = db.prepare(
    `INSERT INTO users (full_name, username, email, password_hash, role, created_at, is_active)
     VALUES (?, ?, ?, ?, ?, ?, 1)`,
  ).run('Test Admin', 'admin', 'admin@test', hashPassword('secret123'), ROLES.ADMIN, Date.now()).lastInsertRowid;
  const studentId = db.prepare(
    `INSERT INTO users (full_name, username, email, password_hash, role, student_id, department, created_at, is_active)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)`,
  ).run('Test Student', 'student', 'student@test', hashPassword('secret123'), ROLES.STUDENT, 'LIB/2025/999', 'CS', Date.now()).lastInsertRowid;
  adminToken = signToken({ id: adminId, role: ROLES.ADMIN, username: 'admin' });
  studentToken = signToken({ id: studentId, role: ROLES.STUDENT, username: 'student' });
});

afterAll(() => {
  try { require('../src/db/connection').closeDb(); } catch (_) {}
});

describe('GET /health', () => {
  test('returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
  });
});

describe('POST /api/auth/login', () => {
  test('logs in admin with username', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ identifier: 'admin', password: 'secret123' });
    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
    expect(res.body.user.username).toBe('admin');
  });

  test('logs in with email', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ identifier: 'student@test', password: 'secret123' });
    expect(res.status).toBe(200);
    expect(res.body.user.username).toBe('student');
  });

  test('rejects wrong password', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ identifier: 'admin', password: 'wrong' });
    expect(res.status).toBe(401);
  });

  test('rejects unknown user', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ identifier: 'nobody', password: 'whatever' });
    expect(res.status).toBe(404);
  });
});

describe('GET /api/auth/me', () => {
  test('returns current user when authenticated', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(res.body.username).toBe('admin');
    expect(res.body.password_hash).toBeUndefined();
  });

  test('401 without token', async () => {
    const res = await request(app).get('/api/auth/me');
    expect(res.status).toBe(401);
  });
});
