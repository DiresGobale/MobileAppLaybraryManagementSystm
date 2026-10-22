/**
 * Tiny CSV serializer — handles quoting / escaping per RFC 4180.
 * Returns a UTF-8 string suitable for `res.type('text/csv').send(...)`.
 *
 *   const csv = toCsv(rows, ['id', 'name']);
 */
function escapeField(value) {
  if (value === null || value === undefined) return '';
  const s = String(value);
  if (/[",\n\r]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function toCsv(rows, columns) {
  if (!rows || rows.length === 0) {
    return columns.map((c) => escapeField(c)).join(',') + '\n';
  }
  const cols = columns || Object.keys(rows[0]);
  const lines = [cols.map(escapeField).join(',')];
  for (const row of rows) {
    lines.push(cols.map((c) => escapeField(row[c])).join(','));
  }
  return lines.join('\n') + '\n';
}

module.exports = { toCsv };
