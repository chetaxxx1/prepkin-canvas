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
  recentFeedback:  { sel: '.events_list.recent_feedback', page: 'any', conf: 'verified', never: true }, // never hidden; restyled as rows
  courseNav:       { sel: '#section-tabs', page: 'course', conf: 'verified' },
  pastCourses:     { sel: '#past_enrollments_table, #future_enrollments_table', page: 'courses', conf: 'likely' },
  // The tables with columns a student never reads (session D, 2026-09-18): All Courses and the InstUI Files table.
  tableColumns:    { sel: '#my_courses_table, #files-table', page: 'courses', conf: 'verified' },
  courseNavLowUse: { sel: '#section-tabs a.files, #section-tabs a.outcomes, #section-tabs a.conferences, #section-tabs a.collaborations', page: 'course', conf: 'verified' },
  moduleHeader:    { sel: '.context_module .ig-header.header', page: 'modules', conf: 'verified' },
  moduleDue:       { sel: '.context_module .due_date_display, .ig-row .ig-details .score-display', page: 'modules', conf: 'verified' },
  // Canvas's bar above the module list: 90px of paper holding one Collapse All.
  // The same bar above the assignments (its search and Show by) and the quizzes (its search).
  moduleBar:       { sel: '#content .header-bar:has(#expand_collapse_all), #content .header-bar:has(.assignment-search), #content .header-bar:has(.ic-Search)', page: 'modules', conf: 'verified' },
  // The Reply link under every announcement row, the row's own link said again.
  replyLink:       { sel: '.ic-item-row [data-testid="announcement-reply"]', page: 'announcements', conf: 'verified' },
  // The discussions index's empty-state drawing, one per section with nothing in it.
  discEmpty:       { sel: '.discussions-v2__container-image', page: 'discussions', conf: 'verified' },
  // A calendar event chip: a link, coloured by its course's own class rule.
  calEvent:        { sel: '#calendar-app .fc-event', page: 'calendar', conf: 'verified' },
  // The Inbox's conversation list (the InstUI Inbox, 2026-09-19).
  inboxList:       { sel: '#inbox-conversation-holder', page: 'inbox', conf: 'verified' },
  // A plain Canvas button (the buttons rule excludes submit, primary and icon-only ones in its own text).
  plainButton:     { sel: '.btn, .Button, .ui-button, #content [class*="-baseButton"]', page: 'any', conf: 'verified' },
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
