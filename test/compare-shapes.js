// Reads what the real Canvas answered (test/recorded/, written by live.test.js)
// and checks every field the fake Canvas and the extension lean on. Prints one
// line per field: how many records had it, and the values seen for the ones
// that are enums. Run: node test/compare-shapes.js

const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, 'recorded');
const files = fs.readdirSync(dir).filter((f) => f.endsWith('.json') && f !== '_first-push.json');
const rows = { assignment: [], course: [], todo: [], group: [], colors: [], self: [] };
for (const f of files) {
  const { path: p, body } = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8'));
  if (!body) continue;
  if (/\/assignments\?/.test(p)) rows.assignment.push(...body);
  else if (/\/assignment_groups/.test(p)) rows.group.push(...body);
  else if (/^\/api\/v1\/courses\?/.test(p)) rows.course.push(...body);
  else if (/users\/self\/todo/.test(p)) rows.todo.push(...body);
  else if (/users\/self\/colors/.test(p)) rows.colors.push(body);
  else if (/users\/self$/.test(p)) rows.self.push(body);
}

const get = (o, k) => k.split('.').reduce((x, part) => (x == null ? undefined : x[part]), o);
function check(kind, field, { enumerate = false } = {}) {
  const list = rows[kind];
  const have = list.filter((r) => get(r, field) !== undefined);
  const values = enumerate ? [...new Set(have.map((r) => JSON.stringify(get(r, field))))].slice(0, 12).join(' ') : '';
  const mark = have.length === list.length ? 'ok ' : have.length ? 'SOME' : 'NONE';
  console.log(`${mark}  ${kind}.${field}  ${have.length}/${list.length}  ${values}`);
}

console.log(`records: ${Object.entries(rows).map(([k, v]) => `${k}=${v.length}`).join(' ')}\n`);
check('self', 'sortable_name'); check('self', 'short_name');
check('course', 'workflow_state', { enumerate: true });
check('course', 'term.end_at');
check('course', 'apply_assignment_group_weights', { enumerate: true });
check('course', 'enrollments.0.type', { enumerate: true });
check('course', 'enrollments.0.computed_current_score');
check('course', 'enrollments.0.computed_current_grade');
check('assignment', 'due_at'); check('assignment', 'points_possible'); check('assignment', 'created_at'); check('assignment', 'html_url');
check('assignment', 'has_overrides', { enumerate: true });
check('assignment', 'quiz_id');
check('assignment', 'submission_types', { enumerate: true });
check('assignment', 'submission.workflow_state', { enumerate: true });
check('assignment', 'submission.submitted_at'); check('assignment', 'submission.graded_at'); check('assignment', 'submission.score');
check('assignment', 'submission.excused', { enumerate: true });
check('assignment', 'submission.missing', { enumerate: true });
check('assignment', 'submission.late', { enumerate: true });
check('todo', 'type', { enumerate: true }); check('todo', 'course_id'); check('todo', 'context_name');
check('todo', 'assignment.id'); check('todo', 'assignment.due_at'); check('todo', 'quiz.id');
check('group', 'group_weight');
check('colors', 'custom_colors');
