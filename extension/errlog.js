// Error records stay small and local until a student chooses to copy them.

/// Keep the useful host while dropping paths that can name coursework.
function safeText(value) {
  return String(value ?? '').replace(/https:\/\/[^\s<>"']+/gi, (raw) => {
    try { return new URL(raw).host; } catch { return '[address removed]'; }
  });
}

/// Add one error without changing the caller's list.
function recordError(list, entry) {
  const next = {
    at: entry?.at,
    where: entry?.where,
    message: safeText(entry?.message).slice(0, 300),
    stack: safeText(entry?.stack).slice(0, 300),
    version: entry?.version,
  };
  return [...(Array.isArray(list) ? list : []), next]
    .sort((a, b) => Date.parse(a.at) - Date.parse(b.at))
    .slice(-20);
}

/// Remove names and values that belong only inside this laptop.
function reportText(value) {
  return safeText(value)
    .replace(/writerToken|pairingCode/gi, '[private]')
    .replace(/\b[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}\b/gi, '[private]')
    .replace(/sync|bridge|endpoint|selector|api|token|schema|payload/gi, '[detail]')
    .replace(/!/g, '');
}

/// Build the short plain-text note a student can paste into an email.
function formatReport(list, { version, chrome }) {
  const header = `Prepkin error report — Extension ${version} — Chrome ${chrome}`;
  const blocks = [...(Array.isArray(list) ? list : [])]
    .sort((a, b) => Date.parse(b.at) - Date.parse(a.at))
    .map((entry) => {
      let at;
      try { at = new Date(entry.at).toISOString(); } catch { at = String(entry.at ?? ''); }
      const lines = [
        `${at} — ${reportText(entry.where)}`,
        reportText(entry.message),
        ...reportText(entry.stack).split('\n').slice(0, 3).filter(Boolean),
      ];
      return lines.join('\n');
    });
  return [header, ...blocks].join('\n\n');
}

if (typeof module !== 'undefined') {
  module.exports = { recordError, formatReport };
}
