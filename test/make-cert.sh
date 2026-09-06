#!/usr/bin/env bash
# A lasting self-signed CA+leaf for https://localhost:8443, kept outside the
# repo, and installed into an iOS simulator so the real app trusts the fake
# bridge. Usage: test/make-cert.sh [simulator name or udid]
set -euo pipefail
DIR="${PREPKIN_CERT_DIR:-$HOME/Library/Developer/prepkin-canvas-test-deps/certs}"
mkdir -p "$DIR"
if [ ! -f "$DIR/cert.pem" ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -keyout "$DIR/key.pem" -out "$DIR/cert.pem" -days 800 \
    -subj '/CN=Prepkin test bridge' \
    -addext 'subjectAltName=DNS:localhost,IP:127.0.0.1' \
    -addext 'basicConstraints=critical,CA:TRUE' \
    -addext 'keyUsage=critical,digitalSignature,keyCertSign' \
    -addext 'extendedKeyUsage=serverAuth'
  echo "made $DIR/cert.pem"
fi
if [ -n "${1:-}" ]; then
  xcrun simctl boot "$1" 2>/dev/null || true
  xcrun simctl keychain "$1" add-root-cert "$DIR/cert.pem"
  echo "trusted in simulator $1"
fi
