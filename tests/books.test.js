const request = require('supertest');
const path = require('path');
const fs = require('fs');

// Reset cached modules so env.js re-reads process.env after we override it.
function freshModules(dbPath) {
  delete require.cache[require.resolve('../src/config/env')];
  delete require.cache[require.resolve('../src/db/connection')];
  delete require.cache[require.resolve('../src/app')];
  process.env.DATABASE_PATH = dbPath;
  try { if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath); } catch (_) {}
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
let librarianToken;
let adminId, libId, studentId;
let categoryId;
let bookId;

beforeAll(() => {
  const dbPath = path.join(__dirname, '..', 'data', `test-books-${process.pid}-${Date.now()}.db`);
  const fresh = freshModules(dbPath);
  app = fresh.app;
  db = fresh.db;
  adminId = db.prepare(
    `INSERT INTO users (full_name, username, email, password_hash, role, created_at, is_active)
     VALUES (?, ?, ?, ?, ?, ?, 1)`,
  ).run('Admin', 'admin', 'admin@test', hashPassword('secret123'), ROLES.ADMIN, Date.now()).lastInsertRowid;
  libId = db.prepare(
    `INSERT INTO users (full_name, username, email, password_hash, role, created_at, is_active)
     VALUES (?, ?, ?, ?, ?, ?, 1)`,
  ).run('Lib', 'librarian', 'lib@test', hashPassword('secret123'), ROLES.LIBRARIAN, Date.now()).lastInsertRowid;
  studentId = db.prepare(
    `INSERT INTO users (full_name, username, email, password_hash, role, student_id, created_at, is_active)
     VALUES (?, ?, ?, ?, ?, ?, ?, 1)`,
  ).run('Stud', 'student', 'stud@test', hashPassword('secret123'), ROLES.STUDENT, 'LIB/2025/001', Date.now()).lastInsertRowid;
  adminToken = signToken({ id: adminId, role: ROLES.ADMIN, username: 'admin' });
  librarianToken = signToken({ id: libId, role: ROLES.LIBRARIAN, username: 'librarian' });
  studentToken = signToken({ id: studentId, role: ROLES.STUDENT, username: 'student' });
  categoryId = db.prepare(
    'INSERT INTO categories (name, description) VALUES (?, ?)',
  ).run('Computer Science', 'CS books').lastInsertRowid;
});

afterAll(() => {
  try { require('../src/db/connection').closeDb(); } catch (_) {}
});

describe('Books API', () => {
  test('librarian can create a book', async () => {
    const res = await request(app)
      .post('/api/books')
      .set('Authorization', `Bearer ${librarianToken}`)
      .send({
        isbn: '978-TEST-1',
        title: 'Introduction to Algorithms',
        author: 'Cormen et al.',
        category_id: categoryId,
        total_quantity: 5,
        available_quantity: 5,
      });
    expect(res.status).toBe(201);
    expect(res.body.id).toBeGreaterThan(0);
    bookId = res.body.id;
  });

  test('rejects duplicate ISBN', async () => {
    const res = await request(app)
      .post('/api/books')
      .set('Authorization', `Bearer ${librarianToken}`)
      .send({
        isbn: '978-TEST-1',
        title: 'Duplicate',
        author: 'X',
        total_quantity: 1,
        available_quantity: 1,
      });
    expect(res.status).toBe(409);
  });

  test('student cannot create a book', async () => {
    const res = await request(app)
      .post('/api/books')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        isbn: '978-NOPE',
        title: 'Should fail',
        author: 'X',
        total_quantity: 1,
        available_quantity: 1,
      });
    expect(res.status).toBe(403);
  });

  test('anyone can search without auth via /public/search', async () => {
    const res = await request(app).get('/api/books/public/search?q=algo');
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThan(0);
    expect(res.body[0].title).toContain('Algorithms');
  });

  test('public inventory stats return totals', async () => {
    const res = await request(app).get('/api/books/public/inventory');
    expect(res.status).toBe(200);
    expect(res.body.titles).toBeGreaterThan(0);
    expect(res.body.totalCopies).toBeGreaterThan(0);
  });

  test('can fetch book by id', async () => {
    const res = await request(app)
      .get(`/api/books/${bookId}`)
      .set('Authorization', `Bearer ${librarianToken}`);
    expect(res.status).toBe(200);
    expect(res.body.title).toBe('Introduction to Algorithms');
    expect(res.body.category_name).toBe('Computer Science');
  });

  test('can update a book', async () => {
    const res = await request(app)
      .patch(`/api/books/${bookId}`)
      .set('Authorization', `Bearer ${librarianToken}`)
      .send({ description: 'A comprehensive algorithms textbook.' });
    expect(res.status).toBe(200);
    expect(res.body.description).toContain('comprehensive');
  });

  test('cannot delete book with active loans', async () => {
    // Issue the book first
    const issueRes = await request(app)
      .post('/api/loans/issue')
      .set('Authorization', `Bearer ${librarianToken}`)
      .send({ userId: studentId, bookId });
    expect(issueRes.status).toBe(201);

    const delRes = await request(app)
      .delete(`/api/books/${bookId}`)
      .set('Authorization', `Bearer ${librarianToken}`);
    expect(delRes.status).toBe(409);
  });
});

describe('Loans API', () => {
  test('librarian can issue a book', async () => {
    // Add another book first
    const bookRes = await request(app)
      .post('/api/books')
      .set('Authorization', `Bearer ${librarianToken}`)
      .send({
        isbn: '978-LOAN-TEST',
        title: 'Loanable Book',
        author: 'Author',
        total_quantity: 2,
        available_quantity: 2,
      });
    expect(bookRes.status).toBe(201);
    const bid = bookRes.body.id;

    const loanRes = await request(app)
      .post('/api/loans/issue')
      .set('Authorization', `Bearer ${librarianToken}`)
      .send({ userId: studentId, bookId: bid });
    expect(loanRes.status).toBe(201);
    expect(loanRes.body.status).toBe('active');
  });

  test('cannot issue book when out of stock', async () => {
    const bookRes = await request(app)
      .post('/api/books')
      .set('Authorization', `Bearer ${librarianToken}`)
      .send({
        isbn: '978-OOStock',
        title: 'Single Copy',
        author: 'X',
        total_quantity: 1,
        available_quantity: 1,
      });
    const bid = bookRes.body.id;
    // Issue the only copy
    await request(app)
      .post('/api/loans/issue')
      .set('Authorization', `Bearer ${librarianToken}`)
      .send({ userId: studentId, bookId: bid });
    // Try to issue again — should fail
    const res = await request(app)
      .post('/api/loans/issue')
      .set('Authorization', `Bearer ${librarianToken}`)
      .send({ userId: studentId, bookId: bid });
    expect(res.status).toBe(409);
  });
});
