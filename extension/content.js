// Runs on every Canvas page. If the student is logged in (Canvas sets ENV with
// a current_user), ask the background worker to sync.
(() => {
  // Logged-out Canvas pages have a login form; logged-in ones expose the user nav.
  const loggedIn = !!document.querySelector('#global_nav_profile_link, #dashboard');
  if (!loggedIn) return;

  chrome.runtime.sendMessage({
    type: 'canvas-detected',
    origin: location.origin,
  });
})();
