// Builders for Canvas API objects, shaped the way Canvas actually sends them,
// so a test reads like the situation it describes:
//
//   assignment({ name: 'Lab 3', due: 2, sub: submitted(-1) })
//
// Dates are days from now. Field names follow the Canvas REST docs; layer 2
// (a real Canvas) is what confirms them.

const { DAY } = require('./fake-canvas');

const NOW = Date.now();
const at = (days, now = NOW) => new Date(now + days * DAY).toISOString();

let nextId = 7000;
const fresh = () => (nextId += 1);

function course({ id = fresh(), name, code = name.toUpperCase().replace(/\W+/g, '-').slice(0, 10),
                  score = 88.5, grade = 'B+', termEnds = 120, state = 'available',
                  role = 'student', enrollment = 'active', weighted = true } = {}) {
  return {
    id, name, course_code: code, workflow_state: state,
    apply_assignment_group_weights: weighted,
    term: termEnds === null ? {} : { id: 1, name: 'Fall 2026', end_at: at(termEnds) },
    enrollments: [{
      type: role, role: role === 'student' ? 'StudentEnrollment' : 'TaEnrollment',
      enrollment_state: enrollment,
      computed_current_score: score, computed_current_grade: grade,
    }],
  };
}

/// The row Canvas returns for work you have not touched.
function unsubmitted() {
  return { workflow_state: 'unsubmitted', submitted_at: null, graded_at: null, score: null,
           grade: null, excused: false, missing: false, late: false, attempt: null };
}

function submitted(days, { score = null, gradedDays = null, late = false } = {}) {
  const graded = score !== null || gradedDays !== null;
  return { workflow_state: graded ? 'graded' : 'submitted', submitted_at: at(days),
           graded_at: graded ? at(gradedDays ?? days + 0.5) : null, score,
           grade: score === null ? null : String(score), excused: false, missing: false, late, attempt: 1 };
}

/// Teacher entered a score, the student never handed anything in. Canvas marks
/// it `missing` and leaves `submitted_at` empty.
function missingZero(gradedDays = -1) {
  return { workflow_state: 'graded', submitted_at: null, graded_at: at(gradedDays), score: 0,
           grade: '0', excused: false, missing: true, late: false, attempt: null };
}

function excused(gradedDays = -1) {
  return { workflow_state: 'graded', submitted_at: null, graded_at: at(gradedDays), score: null,
           grade: null, excused: true, missing: false, late: false, attempt: null };
}

/// Work graded with no online submission — paper, in-class, "no submission".
function paperGraded(score, gradedDays = -1) {
  return { workflow_state: 'graded', submitted_at: null, graded_at: at(gradedDays), score,
           grade: String(score), excused: false, missing: false, late: false, attempt: null };
}

function assignment({ id = fresh(), name = `Assignment ${id}`, due = 3, points = 50, created = -20,
                      sub = unsubmitted(), types = ['online_text_entry'], quizId = null,
                      unlock = null, course = 1, extra = {} } = {}) {
  return {
    id, name, due_at: due === null ? null : at(due), points_possible: points,
    created_at: at(created), unlock_at: unlock === null ? null : at(unlock),
    html_url: `https://localhost:8443/courses/${course}/assignments/${id}`,
    submission_types: types, published: true, has_overrides: false,
    ...(quizId ? { quiz_id: quizId } : {}),
    submission: sub,
    ...extra,
  };
}

function group({ id = fresh(), name, weight }) {
  return { id, name, group_weight: weight, position: 1 };
}

/// A to-do sweep row for a classic quiz, which the assignments list may also
/// carry under a different id.
function todoQuiz({ id = fresh(), title, due = 3, points = 10, courseId, courseName }) {
  return {
    type: 'submitting', context_type: 'Course', course_id: courseId, context_name: courseName,
    quiz: { id, title, due_at: due === null ? null : at(due), points_possible: points,
            html_url: `https://localhost:8443/courses/${courseId}/quizzes/${id}` },
  };
}

/// One ordinary semester: two live courses, the usual spread of states.
function plainSemester() {
  const physics = course({ id: 1, name: 'AP Physics C', code: 'PHYS-C', score: 88.5, grade: 'B+' });
  const english = course({ id: 2, name: 'English 11', code: 'ENG-11', score: null, grade: null });
  return {
    courses: [physics, english],
    colors: { course_1: '#FF6F61', course_2: '#57C79B' },
    assignments: {
      1: [
        assignment({ id: 11, name: 'Problem Set 7', due: 0.1, course: 1 }),
        assignment({ id: 12, name: 'Lab writeup: Momentum', due: 1, course: 1 }),
        assignment({ id: 13, name: 'Problem Set 8', due: 6, course: 1 }),
        assignment({ id: 14, name: 'Problem Set 6', due: -4, course: 1, sub: submitted(-2, { score: 41, late: true }) }),
      ],
      2: [
        assignment({ id: 21, name: 'Close reading', due: -1, course: 2, sub: submitted(-1.5) }),
        assignment({ id: 22, name: 'Rhetorical analysis', due: 9, points: 60, course: 2 }),
      ],
    },
    groups: {
      1: [group({ id: 101, name: 'Problem sets', weight: 40 }), group({ id: 102, name: 'Labs', weight: 60 })],
      2: [group({ id: 201, name: 'Essays', weight: 0 })],
    },
  };
}

module.exports = { NOW, at, course, assignment, group, unsubmitted, submitted, missingZero, excused,
                   paperGraded, todoQuiz, plainSemester, fresh };
