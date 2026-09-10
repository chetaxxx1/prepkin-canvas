// Every Canvas selector the skin leans on, in one place, with the page it lives
// on and how sure we are of it (design/canvas-skin/RESEARCH.md). Nothing else
// in the extension names a Canvas selector.
//
// A rule only goes on the receipt when its hook is actually on the page, so a
// hook that stops matching after a Canvas deploy degrades to "nothing was
// taken", never to a broken page. The live smoke check (test/live.test.js L7)
// asserts each hook still matches on a real Canvas.
//
// Never a selector containing `css-`: those are InstUI content hashes.

const SELECTORS = {
  navRail:         { sel: '#header.ic-app-header', page: 'any', conf: 'verified' },
  headerLogo:      { sel: '.ic-app-header__logomark-container', page: 'any', conf: 'verified' },
  sidebarLogo:     { sel: '.ic-sidebar-logo', page: 'dashboard', conf: 'verified' },
  card:            { sel: '.ic-DashboardCard', page: 'dashboard', conf: 'verified' },
  cardHero:        { sel: '.ic-DashboardCard__header_hero', page: 'dashboard', conf: 'verified' },
  cardActions:     { sel: '.ic-DashboardCard__action-container', page: 'dashboard', conf: 'verified' },
  todoReact:       { sel: '.Sidebar__TodoListContainer', page: 'dashboard', conf: 'verified' },
  todoLegacy:      { sel: 'ul.right-side-list.to-do-list', page: 'dashboard', conf: 'verified' },
  comingUp:        { sel: '.events_list.coming_up', page: 'dashboard', conf: 'verified' },
  comingUpMore:    { sel: '.events_list.coming_up a.more_link', page: 'dashboard', conf: 'verified' },
  recentFeedback:  { sel: '.events_list.recent_feedback', page: 'dashboard', conf: 'verified', never: true },
  courseNav:       { sel: '#section-tabs', page: 'course', conf: 'verified' },
  pastCourses:     { sel: '#past_enrollments_table, #future_enrollments_table', page: 'courses', conf: 'likely' },
  courseNavLowUse: { sel: '#section-tabs a.files, #section-tabs a.outcomes, #section-tabs a.conferences, #section-tabs a.collaborations', page: 'course', conf: 'verified' },
  moduleHeader:    { sel: '.context_module .ig-header.header', page: 'modules', conf: 'verified' },
  moduleDue:       { sel: '.context_module .due_date_display', page: 'modules', conf: 'verified' },
  userContent:     { sel: '.user_content', page: 'assignment', conf: 'verified' },
  gradesReact:     { sel: '#grade-summary-react', page: 'grades', conf: 'verified' },
  gradesTable:     { sel: '#grades_summary', page: 'grades', conf: 'verified' },
  ltiFrame:        { sel: '.tool_content_wrapper', page: 'lti', conf: 'verified' },
  newQuizzes:      { sel: 'body.native-new-quizzes', page: 'quiz', conf: 'verified' },
  rce:             { sel: '.tox-tinymce, .rce-wrapper, [data-rce-wrapper]', page: 'any', conf: 'likely' },
  flashError:      { sel: '.ic-flash-error', page: 'any', conf: 'verified', never: true },
  skipLink:        { sel: '#skip_navigation_link', page: 'any', conf: 'verified', never: true },
};

if (typeof module !== 'undefined') module.exports = { SELECTORS };
