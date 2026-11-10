/* C Around download page — no dependencies, no build step */
(function () {
  'use strict';

  // Version chip
  var params = new URLSearchParams(window.location.search);
  var version = params.get('version') || document.body.dataset.version || '';
  var line  = document.getElementById('version-line');
  var value = document.getElementById('version-value');
  if (version && line && value) {
    value.textContent = version.charAt(0) === 'v' ? version : 'v' + version;
    line.hidden = false;
  }

  // Footer year
  var year = document.getElementById('year');
  if (year) year.textContent = String(new Date().getFullYear());

  // Optionally fetch latest release version from GitHub API
  // Only runs when the chip has not been pre-populated via query string
  if (!version) {
    fetch('https://api.github.com/repos/Cambric-software/c-around/releases/latest', {
      headers: { Accept: 'application/vnd.github+json' }
    })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (data) {
        if (!data || !data.tag_name) return;
        var tag = data.tag_name;
        if (line && value) {
          value.textContent = tag.charAt(0) === 'v' ? tag : 'v' + tag;
          line.hidden = false;
        }
      })
      .catch(function () { /* network unavailable — chip stays hidden */ });
  }
})();
