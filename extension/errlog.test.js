const test = require('node:test');
const assert = require('node:assert/strict');

const { recordError, formatReport } = require('./errlog.js');

test('recordError keeps the newest 20 entries', () => {
  let list = [];
  for (let i = 0; i < 25; i += 1) {
    list = recordError(list, {
      at: new Date(Date.UTC(2026, 0, 1, 0, i)).toISOString(),
      where: `place ${i}`,
      message: `message ${i}`,
      stack: '',
      version: '1.0.0',
    });
  }

  assert.equal(list.length, 20);
  assert.equal(list[0].message, 'message 5');
  assert.equal(list[19].message, 'message 24');
});

test('recordError cuts the message and stack to 300 characters', () => {
  const [entry] = recordError([], {
    at: '2026-01-01T00:00:00.000Z',
    where: 'worker',
    message: 'm'.repeat(350),
    stack: 's'.repeat(350),
    version: '1.0.0',
  });

  assert.equal(entry.message, 'm'.repeat(300));
  assert.equal(entry.stack, 's'.repeat(300));
});

test('recordError reduces secure URLs to their hosts', () => {
  const [entry] = recordError([], {
    at: '2026-01-01T00:00:00.000Z',
    where: 'page',
    message: 'Failed at https://school.instructure.com/courses/12/assignments/34?student=56',
    stack: 'run@https://cdn.example.edu/scripts/app.js:10:2',
    version: '1.0.0',
  });

  assert.equal(entry.message, 'Failed at school.instructure.com');
  assert.equal(entry.stack, 'run@cdn.example.edu');
});

test('formatReport includes versions and puts the newest entry first', () => {
  const report = formatReport([
    { at: '2026-01-02T00:00:00.000Z', where: 'newer place', message: 'newer', stack: 'alpha\nbeta\ngamma\ndelta' },
    { at: '2026-01-01T00:00:00.000Z', where: 'older place', message: 'older', stack: 'one\ntwo\nthree\nfour' },
  ], { version: '2.3.4', chrome: '140.0.1' });

  assert.match(report, /2\.3\.4/);
  assert.match(report, /Chrome 140\.0\.1/);
  assert.ok(report.indexOf('newer') < report.indexOf('older'));
  assert.match(report, /alpha\nbeta\ngamma/);
  assert.doesNotMatch(report, /delta/);
});

test('formatReport returns only the header for an empty list', () => {
  assert.equal(
    formatReport([], { version: '2.3.4', chrome: '140.0.1' }),
    'Prepkin error report — Extension 2.3.4 — Chrome 140.0.1'
  );
});

test('formatReport leaves private storage names and codes out', () => {
  const report = formatReport([{
    at: '2026-01-01T00:00:00.000Z',
    where: 'worker',
    message: 'writerToken leaked with pairingCode ABCD-EFGH',
    stack: '',
  }], { version: '2.3.4', chrome: '140.0.1' });

  assert.doesNotMatch(report, /writerToken/);
  assert.doesNotMatch(report, /pairingCode/);
  assert.doesNotMatch(report, /ABCD-EFGH/);
});
