# Security Policy — C Around

**Contact:** security@cambric.dev  
**Response time:** within 48 hours for critical issues; fix target within 14 days.

---

## Reporting a vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Send a report to **security@cambric.dev** with:

1. A clear description of the vulnerability and its potential impact.
2. Steps to reproduce or a minimal proof-of-concept.
3. The affected version(s) and platform(s).
4. Any suggested remediation (optional but appreciated).

We will acknowledge receipt within 48 hours and aim to publish a fix within 14 days for critical issues. We will credit reporters in the release notes unless you request anonymity.

---

## Scope

| Component | In scope |
|---|---|
| C Around Android / Windows / Linux app | ✅ |
| On-device AI models (YOLO, YAMNet, Whisper, face recognizer) | ✅ |
| Update verification and download pipeline | ✅ |
| PIN-based app lock | ✅ |
| SQLite local database | ✅ |
| GitHub Actions CI/CD pipeline | ✅ |
| Download page (GitHub Pages) | ✅ |
| Third-party dependencies (Flutter, sherpa-onnx, onnxruntime, etc.) | ⚠️ report upstream; CC us |

---

## Security model

C Around is **local-first**. The threat model prioritises:

1. **Data confidentiality** — user data (faces, phrases, medical card, captions) must not leave the device without explicit user action.
2. **Model integrity** — downloaded model packs are verified with SHA-256 before use.
3. **Update integrity** — release artifacts include companion `.sha256` files; the app verifies them before installing.
4. **PIN protection** — the app lock uses PBKDF2-SHA-256 (10,000 iterations) to hash the PIN; the hash is stored in SharedPreferences and never transmitted.
5. **No remote attack surface** — there is no server, no API key and no authentication endpoint. The only outbound network request is a GET to `api.github.com/repos/Cambric-software/c-around/releases/latest`.

---

## What the app does NOT do

- It does **not** upload camera frames, audio, faces or any other sensor data.
- It does **not** have an account system, login or cloud sync.
- It does **not** use third-party analytics or crash-reporting SDKs.
- It does **not** store biometric data outside the device (face embeddings are float vectors in a local SQLite database).
- Moondream (optional desktop-only vision model) runs as a **localhost-only** llama-server process; no request leaves the machine.

---

## Provided security infrastructure

### Input sanitisation
`InputSanitizationService` — all user input is sanitised before storage or display:
- `trimWhitespace`, `toSafeIdentifier`, `sanitizeFilename`
- `escapeHtml`, `validateEmail`, `validateUrl`
- `looksLikeSecret` — detects accidental secret values

### Atomic writes
`AtomicFileService` — all persistent writes use write-to-temp then rename, preventing corruption on power loss.

### Secret redaction
`SecretRedactionService` — redacts private keys, API tokens, passwords and GitHub tokens before logging or exporting diagnostic reports.

### Hashing and integrity
`SecurityService`:
- `sha256String`, `sha256Bytes`, `sha256File`
- `constantTimeEquals` — timing-safe comparison
- `generateIntegrityTag` / `verifyIntegrityTag` — HMAC-SHA256
- `verifyFileChecksum` — file integrity check

### App lock
`AppLockService` — optional PIN lock:
- 6-digit PIN hashed with PBKDF2-SHA-256 (10,000 iterations + random salt)
- Lockout after 5 failed attempts (5-minute delay)
- Hash stored in `SharedPreferences`; never transmitted

### Update verification
`UpdateVerificationService` — verifies every downloaded package before installation:
- File exists and is non-empty
- SHA-256 checksum matches the companion `.sha256` published with the release
- Verification failure blocks installation

---

## Dependency auditing

The `security.yml` CI workflow runs on every push:

- `dart pub audit` — checks all transitive dependencies for known CVEs
- Grep scan of `lib/` for hardcoded credential patterns
- Check that no `.env` or secret files have been committed

---

## Supported versions

| Version | Supported |
|---|---|
| Latest release | ✅ |
| Previous release | ⚠️ best-effort |
| Older releases | ❌ please upgrade |

---

## Legal notice

Unauthorised security research that exploits vulnerabilities beyond read-only inspection, extracts user data from other users' devices, or violates applicable law is not authorised and will be prosecuted. Responsible disclosure under this policy is explicitly authorised.

© 2026 Cambric Software.
