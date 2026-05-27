# sys-web-deployment.md

## Local Development

```bash
cd /Users/Shared/repos/AIPrivateSearch/repo/aiprivatesearchweb
npm install
npm start        # starts backend on port 56303
# In separate terminal:
node client/c01_client-marketing/server.mjs  # starts frontend on port 56302
```

Access at: http://localhost:56302

## Environment Variables

No `.env` file required for the marketing site. Port configuration is in:
```
client/c01_client-marketing/config/app.json
```

```json
{
  "ports": {
    "frontend": 56302,
    "backend": 56303
  }
}
```

## Remote Server Deployment

Server: Ubuntu Linux at formr/aiprivatesearch.com

```bash
cd /webs/AIPrivateSearch/repo/aiprivatesearchweb
git pull
git lfs pull     # required to get latest DMG
```

The web server (Caddy/Nginx) serves the static files and proxies API requests.

## DMG Build and Release Pipeline

Full pipeline (run on dev Mac only — requires signing certificate):

```bash
cd installer
bash build-all.sh
```

This will:
1. Prepare resources (download Node.js arm64, copy Ollama)
2. Build `AIPrivateSearch.app` with Swift universal binary launcher
3. Build DMG
4. Sign app bundle with Developer ID Application certificate
5. Rebuild DMG with signed app
6. Sign DMG
7. Notarize with Apple (2-15 min)
8. Staple notarization ticket
9. Copy DMG to `client/c01_client-marketing/downloads/`

**If clock sync error during signing:**
```bash
sudo sntp -sS time.apple.com
```

**Then commit and push manually:**
```bash
git add -A && git commit -m "vX.XX: description" && git push
```

Git LFS uploads the DMG automatically on push.

## Version Bump Files

On every release, update version in:
1. `README.md` — `**Version**: X.XX`
2. `package.json` — `"version": "X.XX"`
3. `client/c01_client-marketing/shared/footer.html` — `<span class="app-version">vX.XX</span>`

Use the `release` command in Amazon Q to bump all three automatically.

## Signing Credentials

Stored at `~/.aips/signing-credentials.sh` (gitignored, safe from uninstaller):
```bash
export APPLE_ID="bruce.troutman@gmail.com"
export APPLE_TEAM_ID="5YY6H9M6Q3"
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export SIGNING_IDENTITY="Developer ID Application: CHARLES TROUTMAN (5YY6H9M6Q3)"
```

Keychain: `~/Library/Keychains/aips-signing.keychain-db` (password: `aips123`)

See `installer/APPLE-CERTIFICATION-PLAN.md` for full certificate setup steps.
