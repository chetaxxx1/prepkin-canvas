// Stands in for the iOS app against a bridge — the fake one, or the real
// Supabase project once bridge/schema.sql is live there. Speaks the same seven
// functions the app does, so a test can claim a code, read what the extension
// pushed, and publish coins back.

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function makeCode() {
  const pick = () => ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
  const s = Array.from({ length: 8 }, pick).join('');
  return `${s.slice(0, 4)}-${s.slice(4)}`;
}

class FakePhone {
  constructor(url, key = 'test-key') {
    this.url = url; this.key = key; this.code = null; this.token = null;
  }

  async rpc(fn, body) {
    const res = await fetch(`${this.url}/rest/v1/rpc/${fn}`, {
      method: 'POST',
      headers: { apikey: this.key, Authorization: `Bearer ${this.key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const text = await res.text();
    return { status: res.status, body: text ? JSON.parse(text) : null };
  }

  /// Rolls codes until one is free, like the app does.
  async claim() {
    for (let i = 0; i < 5; i += 1) {
      const code = makeCode();
      const { status, body } = await this.rpc('claim_code', { p_code: code });
      if (status === 200 && typeof body === 'string') { this.code = code; this.token = body; return code; }
    }
    throw new Error('could not claim a code');
  }

  async fetchTodo() {
    return (await this.rpc('fetch_todo', { p_code: this.code, p_token: this.token })).body;
  }

  async pushState({ coins, owned = ['classic'], requestsAppliedAt = null, league = null }) {
    const p_state = { coins, owned };
    if (requestsAppliedAt) p_state.requestsAppliedAt = requestsAppliedAt;
    if (league) p_state.league = league;
    return this.rpc('push_state', { p_code: this.code, p_token: this.token, p_state });
  }

  async unpair() {
    return this.rpc('delete_pairing', { p_code: this.code, p_token: this.token });
  }
}

module.exports = { FakePhone, makeCode, ALPHABET };
