# DMG Verification Test Plan

## Objective
Verify AIPrivateSearch.dmg consistency across all locations and identify discrepancies.

---

## Test 1: Dev Mac (Local Build)

**Location:** `/Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb/installer/AIPrivateSearch.dmg`

```bash
# Check file info
ls -lh AIPrivateSearch.dmg
stat -f "%Sm %z" AIPrivateSearch.dmg
md5 AIPrivateSearch.dmg

# Mount and check contents
open AIPrivateSearch.dmg
sleep 2
ls -la /Volumes/AIPrivateSearch/
ls -la /Volumes/AIPrivateSearch/*.app
```

**Expected Result:** Single `AIPrivateSearch.app` (unified manager)

---

## Test 2: Dev Mac (Downloads Folder)

**Location:** `/Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb/client/c01_client-marketing/downloads/AIPrivateSearch.dmg`

```bash
cd /Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb

# Check file info
ls -lh client/c01_client-marketing/downloads/AIPrivateSearch.dmg
stat -f "%Sm %z" client/c01_client-marketing/downloads/AIPrivateSearch.dmg
md5 client/c01_client-marketing/downloads/AIPrivateSearch.dmg

# Check git status
git status client/c01_client-marketing/downloads/AIPrivateSearch.dmg
```

**Expected Result:** Same MD5 as Test 1, committed to git

---

## Test 3: GitHub

**Location:** `https://github.com/[your-repo]/client/c01_client-marketing/downloads/AIPrivateSearch.dmg`

```bash
# Check last commit
git log -1 --stat client/c01_client-marketing/downloads/AIPrivateSearch.dmg

# Verify pushed
git diff origin/main client/c01_client-marketing/downloads/AIPrivateSearch.dmg
```

**Expected Result:** No diff, file pushed to GitHub

---

## Test 4: Remote Server

**Location:** `/Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb/client/c01_client-marketing/downloads/AIPrivateSearch.dmg`

```bash
# SSH to server
ssh user@server

cd /Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb

# Check file info
ls -lh client/c01_client-marketing/downloads/AIPrivateSearch.dmg
stat -f "%Sm %z" client/c01_client-marketing/downloads/AIPrivateSearch.dmg
md5 client/c01_client-marketing/downloads/AIPrivateSearch.dmg

# Check git status
git status
git log -1 client/c01_client-marketing/downloads/AIPrivateSearch.dmg
```

**Expected Result:** Same MD5 as Test 1, up to date with GitHub

---

## Test 5: Remote Mac Mini (Downloaded)

**Location:** `~/Downloads/AIPrivateSearch.dmg`

```bash
# On Mac Mini
cd ~/Downloads

# Check file info
ls -lh AIPrivateSearch.dmg
stat -f "%Sm %z" AIPrivateSearch.dmg
md5 AIPrivateSearch.dmg

# Mount and check contents
open AIPrivateSearch.dmg
sleep 2
ls -la /Volumes/AIPrivateSearch/
ls -la /Volumes/AIPrivateSearch/*.app
```

**Expected Result:** Same MD5 as Test 1, single `AIPrivateSearch.app`

---

## Verification Checklist

| Location | File Size | Modified Date | MD5 Hash | Contents | Status |
|----------|-----------|---------------|----------|----------|--------|
| Dev Mac (installer/) | | | | | |
| Dev Mac (downloads/) | | | | | |
| GitHub | | | | | |
| Remote Server | | | | | |
| Mac Mini | | | | | |

**Pass Criteria:** All MD5 hashes match, all show single `AIPrivateSearch.app`

---

## Troubleshooting Steps

### If MD5 doesn't match:
1. Check git status on dev Mac
2. Verify file is committed: `git log -1 --stat client/c01_client-marketing/downloads/AIPrivateSearch.dmg`
3. Push if needed: `git push`
4. Pull on server: `git pull`
5. Re-download on Mac Mini

### If contents show 2 apps (installer/start):
1. Rebuild on dev Mac: `cd installer && ./build-all.sh`
2. Copy to downloads: `cp AIPrivateSearch.dmg ../client/c01_client-marketing/downloads/`
3. Commit and push
4. Pull on server
5. Re-download on Mac Mini

### If browser cache issue:
1. Clear browser cache on Mac Mini
2. Download with timestamp: Add `?v=$(date +%s)` to URL
3. Or use direct server path instead of web download
