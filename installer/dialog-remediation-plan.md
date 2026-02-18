# Dialog System Remediation Plan

## Executive Summary

This document provides a step-by-step remediation plan for fixing all dialog system issues found in the AIPrivateSearch installer. Based on comprehensive analysis in `dialog-logic.md`, we've identified 5 critical bugs and 3 inconsistencies that prevent proper dialog display and UPDATE_MODE functionality.

---

## Issues Summary

### Critical Issues (Must Fix)
1. **Missing `esac`** - Outer case statement never closes (Line 127)
2. **AppleScript Syntax Error** - Multi-line `-e` flag breaks osascript (Lines 781-784)
3. **Missing Cancel Button** - "Show detailed messages" dialog has no Cancel option (Line 194)
4. **Error Suppression** - All errors hidden with `2>/dev/null` and `|| true`
5. **Missing Case Branches** - "Start App" and default branches missing from outer case

### Non-Critical Issues (Should Fix)
6. **Inconsistent Error Handling** - Mix of `2>/dev/null`, `|| true`, and no handling
7. **Variable Scope Documentation** - UPDATE_MODE scope unclear
8. **Progress Dialog Design** - No Cancel button in `show_progress()` function

---

## Phase 1: Fix Critical Syntax Errors

### Step 1.1: Fix Missing `esac` Statement

**Location:** Line 127 (after line 126 `;;`)

**Current Code (BROKEN):**
```bash
        "Update")
            UPDATE_CHOICE=$(osascript...)
            case "$UPDATE_CHOICE" in
                "Update")
                    UPDATE_MODE="true"
                    ;;
                # ... other cases
            esac
            # Continue to installation below
            ;;
        # ❌ MISSING: "Start App" case
        # ❌ MISSING: "*" default case
        # ❌ MISSING: esac to close outer case!
else
    # Not installed
fi
```

**Fixed Code:**
```bash
        "Update")
            UPDATE_CHOICE=$(osascript...)
            case "$UPDATE_CHOICE" in
                "Update")
                    UPDATE_MODE="true"
                    ;;
                "Uninstall")
                    osascript -e 'display dialog "Uninstall feature coming soon" buttons {"OK"} with icon note'
                    exit 0
                    ;;
                *)
                    echo "Update cancelled"
                    exit 0
                    ;;
            esac
            # Continue to installation below
            ;;
        "Start App")
            osascript -e 'display dialog "Start App feature coming soon" buttons {"OK"} with icon note'
            exit 0
            ;;
        *)
            echo "Cancelled"
            exit 0
            ;;
    esac  # ← ADD THIS LINE!
else
    # Not installed
fi
```

**Test Scenario 1.1:**
```bash
# Build and run
cd /Users/Shared/repos/AIPrivateSearch/repo/aiprivatesearchweb/installer
./build-all.sh

# Test Update path
open build/AIPrivateSearch.app
# Click: Update → Update
# Expected: Should reach installation logic without bash errors
# Check: Terminal should NOT show "syntax error near unexpected token 'else'"
```

**Validation:**
```bash
# Check syntax
bash -n build/AIPrivateSearch.app/Contents/MacOS/AIPrivateSearch
# Expected: No output = valid syntax
```

---

### Step 1.2: Fix AppleScript Syntax Error (Lines 781-784)

**Location:** Lines 781-784

**Current Code (BROKEN):**
```bash
if [ "$UPDATE_MODE" = "true" ]; then
    osascript -e 'display dialog "Config files preserved\nData files preserved" 
        with title "UPDATE_MODE=TRUE" 
        buttons {"Continue"} default button "Continue"' || true
else
    osascript -e 'display dialog "Config files copied\nData files copied" 
        with title "UPDATE_MODE=EMPTY" 
        buttons {"Continue"} default button "Continue"' || true
fi
```

**Problem:** Multi-line string in single `-e` flag. Bash interprets newline as command termination.

**Fixed Code (Option A - Single Line):**
```bash
if [ "$UPDATE_MODE" = "true" ]; then
    osascript -e 'display dialog "Config files preserved" & linefeed & "Data files preserved" with title "UPDATE_MODE=TRUE" buttons {"Continue"} default button "Continue"'
else
    osascript -e 'display dialog "Config files copied" & linefeed & "Data files copied" with title "UPDATE_MODE=EMPTY" buttons {"Continue"} default button "Continue"'
fi
```

**Fixed Code (Option B - Heredoc, Recommended):**
```bash
if [ "$UPDATE_MODE" = "true" ]; then
    osascript <<-APPLESCRIPT
        display dialog "Config files preserved" & linefeed & "Data files preserved" \
            with title "UPDATE_MODE=TRUE" \
            buttons {"Continue"} default button "Continue"
    APPLESCRIPT
else
    osascript <<-APPLESCRIPT
        display dialog "Config files copied" & linefeed & "Data files copied" \
            with title "UPDATE_MODE=EMPTY" \
            buttons {"Continue"} default button "Continue"
    APPLESCRIPT
fi
```

**Test Scenario 1.2:**
```bash
# Test AppleScript syntax directly
osascript -e 'display dialog "Config files preserved" & linefeed & "Data files preserved" with title "UPDATE_MODE=TRUE" buttons {"Continue"} default button "Continue"'
# Expected: Dialog appears with two lines of text

# Test in full build
./build-all.sh
open build/AIPrivateSearch.app
# Click: Update → Update → Continue through installation
# Expected: Dialog appears showing "UPDATE_MODE=TRUE" or "UPDATE_MODE=EMPTY"
```

**Validation:**
```bash
# Check if dialog code exists in built app
grep "UPDATE_MODE=TRUE" build/AIPrivateSearch.app/Contents/MacOS/AIPrivateSearch
# Expected: Should find the dialog code
```

---

### Step 1.3: Add Cancel Button to "Show Detailed Messages" Dialog

**Location:** Line 194

**Current Code:**
```bash
SHOW_DETAILS=$(osascript <<-APPLESCRIPT 2>/dev/null
    tell application "System Events"
        activate
        display dialog "Show detailed installation messages in Terminal?\n\nThis will open a Terminal window showing real-time installation progress." buttons {"No", "Yes"} default button "Yes" with title "AIPrivateSearch Installer" with icon note
    end tell
    return button returned of result
APPLESCRIPT
)
```

**Issue:** No Cancel button - user must choose Yes or No, cannot cancel installation.

**Fixed Code:**
```bash
SHOW_DETAILS=$(osascript <<-APPLESCRIPT
    tell application "System Events"
        activate
        display dialog "Show detailed installation messages in Terminal?\n\nThis will open a Terminal window showing real-time installation progress." buttons {"Cancel", "No", "Yes"} default button "Yes" with title "AIPrivateSearch Installer" with icon note
    end tell
    return button returned of result
APPLESCRIPT
)

# Handle Cancel
if [ "$SHOW_DETAILS" = "Cancel" ]; then
    echo "Installation cancelled by user"
    exit 0
fi
```

**Test Scenario 1.3:**
```bash
# Build and test
./build-all.sh
open build/AIPrivateSearch.app

# Test 1: Click Cancel
# Expected: App exits immediately, no installation starts

# Test 2: Click No
# Expected: Installation continues without Terminal window

# Test 3: Click Yes
# Expected: Terminal window opens with tail -f, installation continues
```

**Validation:**
```bash
# Check button count
grep -A 2 "Show detailed installation messages" build/AIPrivateSearch.app/Contents/MacOS/AIPrivateSearch | grep buttons
# Expected: Should show {"Cancel", "No", "Yes"}
```

---

## Phase 2: Remove Error Suppression for Debugging

### Step 2.1: Remove `|| true` from UPDATE_MODE Dialogs

**Location:** Lines 781, 784

**Current Code:**
```bash
osascript -e '...' || true
```

**Fixed Code:**
```bash
osascript <<-APPLESCRIPT
    # ... dialog code
APPLESCRIPT
```

**Rationale:** The `|| true` hides all AppleScript errors. Remove it to see actual failures.

**Test Scenario 2.1:**
```bash
# Build with error suppression removed
./build-all.sh
open build/AIPrivateSearch.app

# Run Update path
# Expected: If dialog fails, script will exit with error message
# Check: Terminal shows actual AppleScript error (if any)
```

---

### Step 2.2: Temporarily Remove `2>/dev/null` from Critical Dialogs

**Locations:** Lines 129, 191, 202, 240, 264

**Current Code:**
```bash
osascript <<-APPLESCRIPT 2>/dev/null
    # ... dialog code
APPLESCRIPT
```

**Fixed Code (Temporary for Debugging):**
```bash
osascript <<-APPLESCRIPT
    # ... dialog code
APPLESCRIPT
```

**Rationale:** See actual AppleScript errors during testing.

**Test Scenario 2.2:**
```bash
# Build without error suppression
./build-all.sh
open build/AIPrivateSearch.app

# Test all dialog paths:
# 1. Fresh install
# 2. Update
# 3. Cancel at each dialog

# Expected: Any AppleScript errors will show in Terminal
# Check: All dialogs appear correctly
```

**Note:** After debugging, add back `2>/dev/null` to production code for clean user experience.

---

## Phase 3: Add Debug Logging

### Step 3.1: Add UPDATE_MODE Debug Statements

**Location:** After line 111 (where UPDATE_MODE is set)

**Add Code:**
```bash
# Line 111: Set UPDATE_MODE
UPDATE_MODE="true"
echo "[DEBUG] UPDATE_MODE set to: $UPDATE_MODE" >> "$LOG_FILE"
echo "[DEBUG] UPDATE_MODE set to: $UPDATE_MODE"  # Also to stdout

# After line 127 (after esac)
echo "[DEBUG] After case statement, UPDATE_MODE=$UPDATE_MODE" >> "$LOG_FILE"
echo "[DEBUG] After case statement, UPDATE_MODE=$UPDATE_MODE"

# Before line 781 (before UPDATE_MODE dialog)
echo "[DEBUG] About to show UPDATE_MODE dialog, value=$UPDATE_MODE" >> "$LOG_FILE"
echo "[DEBUG] About to show UPDATE_MODE dialog, value=$UPDATE_MODE"
```

**Test Scenario 3.1:**
```bash
# Build with debug logging
./build-all.sh

# In separate terminal, watch log
tail -f /Users/Shared/AIPrivateSearch/logs/install.log

# Run app
open build/AIPrivateSearch.app
# Click: Update → Update

# Expected log output:
# [DEBUG] UPDATE_MODE set to: true
# [DEBUG] After case statement, UPDATE_MODE=true
# [DEBUG] About to show UPDATE_MODE dialog, value=true
```

**Validation:**
```bash
# Check log file
grep "UPDATE_MODE" /Users/Shared/AIPrivateSearch/logs/install.log
# Expected: Should see all three debug messages with "true"
```

---

### Step 3.2: Add Dialog Execution Tracing

**Location:** Before each osascript call

**Add Code:**
```bash
# Before line 88 (main menu)
echo "[DIALOG] Showing main menu (already installed)" >> "$LOG_FILE"

# Before line 100 (update submenu)
echo "[DIALOG] Showing update submenu" >> "$LOG_FILE"

# Before line 129 (install menu)
echo "[DIALOG] Showing install menu (not installed)" >> "$LOG_FILE"

# Before line 191 (show details)
echo "[DIALOG] Showing detailed messages prompt" >> "$LOG_FILE"

# Before line 781 (UPDATE_MODE dialog)
echo "[DIALOG] Showing UPDATE_MODE=$UPDATE_MODE dialog" >> "$LOG_FILE"
```

**Test Scenario 3.2:**
```bash
# Build with dialog tracing
./build-all.sh

# Watch log
tail -f /Users/Shared/AIPrivateSearch/logs/install.log

# Run app and test all paths
open build/AIPrivateSearch.app

# Expected: Log shows which dialogs are attempted
# Validation: Compare log to actual dialogs shown
```

---

## Phase 4: Comprehensive Testing

### Test Suite 1: Fresh Install Path

**Precondition:** Remove existing installation
```bash
rm -rf /Users/Shared/AIPrivateSearch/repo/aiprivatesearch
```

**Test 1.1: Fresh Install with Cancel**
```bash
open build/AIPrivateSearch.app
# Click: Cancel
# Expected: App exits immediately
# Validation: Check no files created in /Users/Shared/AIPrivateSearch/
```

**Test 1.2: Fresh Install with No Details**
```bash
open build/AIPrivateSearch.app
# Click: Install → No
# Expected: Installation proceeds without Terminal window
# Validation: Check installation completes, no Terminal opens
```

**Test 1.3: Fresh Install with Yes Details**
```bash
open build/AIPrivateSearch.app
# Click: Install → Yes
# Expected: Terminal window opens with tail -f, installation proceeds
# Validation: Check Terminal shows log messages, installation completes
```

**Test 1.4: Fresh Install with Cancel on Details Dialog**
```bash
open build/AIPrivateSearch.app
# Click: Install → Cancel (on details dialog)
# Expected: App exits, no installation
# Validation: Check no files created
```

---

### Test Suite 2: Update Path

**Precondition:** Existing installation present
```bash
# Ensure installation exists
ls -la /Users/Shared/AIPrivateSearch/repo/aiprivatesearch
```

**Test 2.1: Update with Cancel on Main Menu**
```bash
open build/AIPrivateSearch.app
# Click: Cancel
# Expected: App exits immediately
# Validation: Check existing installation unchanged
```

**Test 2.2: Update with Cancel on Update Submenu**
```bash
open build/AIPrivateSearch.app
# Click: Update → Cancel
# Expected: App exits
# Validation: Check existing installation unchanged
```

**Test 2.3: Update with No Details**
```bash
open build/AIPrivateSearch.app
# Click: Update → Update → No
# Expected: Update proceeds without Terminal window
# Validation: Check UPDATE_MODE=TRUE dialog appears
```

**Test 2.4: Update with Yes Details**
```bash
open build/AIPrivateSearch.app
# Click: Update → Update → Yes
# Expected: Terminal opens, UPDATE_MODE=TRUE dialog appears
# Validation: Check log shows UPDATE_MODE=true
```

**Test 2.5: Update with Cancel on Details Dialog**
```bash
open build/AIPrivateSearch.app
# Click: Update → Update → Cancel (on details dialog)
# Expected: App exits, no update performed
# Validation: Check existing installation unchanged
```

---

### Test Suite 3: Start App Path (Not Implemented)

**Test 3.1: Start App**
```bash
open build/AIPrivateSearch.app
# Click: Start App
# Expected: Dialog shows "Start App feature coming soon"
# Validation: App exits cleanly
```

---

### Test Suite 4: Uninstall Path (Not Implemented)

**Test 4.1: Uninstall**
```bash
open build/AIPrivateSearch.app
# Click: Update → Uninstall
# Expected: Dialog shows "Uninstall feature coming soon"
# Validation: App exits cleanly
```

---

### Test Suite 5: AppleScript Error Handling

**Test 5.1: Intentionally Trigger AppleScript Syntax Error**

**Purpose:** Verify that AppleScript errors are visible when error suppression is removed.

**Setup:** Temporarily break AppleScript syntax in UPDATE_MODE dialog (line 781)

**Broken Code:**
```bash
if [ "$UPDATE_MODE" = "true" ]; then
    osascript <<-APPLESCRIPT
        display dialog "Config files preserved" & linefeed & "Data files preserved" \
            with title "UPDATE_MODE=TRUE" \
            buttons {"Continue" default button "Continue"  # ← MISSING CLOSING BRACE
    APPLESCRIPT
fi
```

**Test Steps:**
```bash
# 1. Edit build-install-app.sh and break syntax at line 781
# 2. Build
./build-all.sh

# 3. Run update path
open build/AIPrivateSearch.app
# Click: Update → Update → Yes

# Expected error in Terminal:
# syntax error: Expected end of line but found identifier. (-2741)
# OR
# Expected "}" but found end of script. (-2741)
```

**Validation:**
- Error message appears in Terminal (not hidden)
- Script exits with non-zero exit code
- User sees error, not silent failure

**Cleanup:** Fix syntax and rebuild

---

**Test 5.2: Test Error Suppression Behavior**

**Purpose:** Compare behavior with and without error suppression.

**Test A - With Error Suppression (Current):**
```bash
osascript -e 'display dialog "Test" buttons {"OK" default button "OK"' 2>/dev/null || true
# Expected: No error shown, script continues
```

**Test B - Without Error Suppression (Recommended for Debugging):**
```bash
osascript -e 'display dialog "Test" buttons {"OK" default button "OK"'
# Expected: Error shown in Terminal:
# syntax error: Expected "}" but found identifier. (-2741)
# Script exits with error
```

**Test Command:**
```bash
# Test directly in terminal
echo "Test with error suppression:"
osascript -e 'display dialog "Test" buttons {"OK" default button "OK"' 2>/dev/null || true
echo "Exit code: $?"

echo "Test without error suppression:"
osascript -e 'display dialog "Test" buttons {"OK" default button "OK"'
echo "Exit code: $?"
```

**Expected Output:**
```
Test with error suppression:
Exit code: 0

Test without error suppression:
syntax error: Expected "}" but found identifier. (-2741)
Exit code: 1
```

---

### Test Suite 6: UPDATE_MODE Variable Persistence

**Test 6.1: Verify UPDATE_MODE=true in Update Path**
```bash
# Watch log
tail -f /Users/Shared/AIPrivateSearch/logs/install.log

# Run update
open build/AIPrivateSearch.app
# Click: Update → Update → Yes

# Expected log output:
# [DEBUG] UPDATE_MODE set to: true
# [DEBUG] After case statement, UPDATE_MODE=true
# [DEBUG] About to show UPDATE_MODE dialog, value=true

# Expected dialog:
# Title: "UPDATE_MODE=TRUE"
# Message: "Config files preserved\nData files preserved"
```

**Test 6.2: Verify UPDATE_MODE=false in Fresh Install Path**
```bash
# Remove installation
rm -rf /Users/Shared/AIPrivateSearch/repo/aiprivatesearch

# Watch log
tail -f /Users/Shared/AIPrivateSearch/logs/install.log

# Run install
open build/AIPrivateSearch.app
# Click: Install → Yes

# Expected log output:
# [DEBUG] UPDATE_MODE set to: false (or not set)
# [DEBUG] After case statement, UPDATE_MODE=false
# [DEBUG] About to show UPDATE_MODE dialog, value=false

# Expected dialog:
# Title: "UPDATE_MODE=EMPTY"
# Message: "Config files copied\nData files copied"
```

---

## Phase 5: Validation Checklist

### Syntax Validation
- [ ] `bash -n build/AIPrivateSearch.app/Contents/MacOS/AIPrivateSearch` returns no errors
- [ ] All `if` statements have matching `fi`
- [ ] All `case` statements have matching `esac`
- [ ] All heredocs have matching delimiters

### Dialog Validation
- [ ] Main menu shows 3 buttons: Cancel, Update, Start App
- [ ] Update submenu shows 3 buttons: Cancel, Update, Uninstall
- [ ] Install menu shows 2 buttons: Cancel, Install
- [ ] Details prompt shows 3 buttons: Cancel, No, Yes
- [ ] UPDATE_MODE dialog shows correct title based on mode

### Variable Validation
- [ ] UPDATE_MODE="true" in Update path
- [ ] UPDATE_MODE="false" (or empty) in Install path
- [ ] SHOW_DETAILS captures button choice correctly
- [ ] All variables persist through case statement

### Flow Validation
- [ ] Cancel on any dialog exits cleanly
- [ ] Update path reaches installation logic
- [ ] Install path reaches installation logic
- [ ] Start App shows "coming soon" and exits
- [ ] Uninstall shows "coming soon" and exits

### Log Validation
- [ ] Debug messages appear in log file
- [ ] UPDATE_MODE value logged correctly
- [ ] Dialog execution traced in log
- [ ] No AppleScript errors in log

---

## Phase 6: Cleanup and Production

### Step 6.1: Remove Debug Logging

After all tests pass, remove debug statements:
```bash
# Remove all lines containing:
echo "[DEBUG]"
echo "[DIALOG]"
```

### Step 6.2: Re-add Error Suppression

Add back `2>/dev/null` to user-facing dialogs for clean experience:
```bash
# Lines 129, 191, 202, 240, 264
osascript <<-APPLESCRIPT 2>/dev/null
```

**Keep error handling for critical dialogs:**
```bash
# Line 781 - UPDATE_MODE dialog should NOT suppress errors
osascript <<-APPLESCRIPT
    # ... dialog code
APPLESCRIPT
```

### Step 6.3: Final Build and Test

```bash
# Clean build
rm -rf build/
./build-all.sh

# Run all test suites again
# Expected: All tests pass without debug output
```

---

## Success Criteria

### Must Have (Critical)
1. ✅ Bash syntax valid (no errors from `bash -n`)
2. ✅ UPDATE_MODE=TRUE dialog appears in Update path
3. ✅ UPDATE_MODE=EMPTY dialog appears in Install path
4. ✅ Cancel button works on all dialogs
5. ✅ No AppleScript syntax errors

### Should Have (Important)
6. ✅ Debug logging shows UPDATE_MODE value correctly
7. ✅ All dialog paths tested and working
8. ✅ Error handling consistent across all dialogs
9. ✅ Log file captures all important events

### Nice to Have (Optional)
10. ✅ Progress dialogs have Cancel button (or auto-dismiss)
11. ✅ Start App and Uninstall implemented (future)
12. ✅ Icon caching issues resolved

---

## Rollback Plan

If any phase fails:

1. **Revert to last working commit:**
```bash
git checkout HEAD~1 installer/build-install-app.sh
```

2. **Rebuild:**
```bash
./build-all.sh
```

3. **Test basic functionality:**
```bash
open build/AIPrivateSearch.app
# Verify app launches and shows dialogs
```

---

## Timeline Estimate

- **Phase 1 (Critical Fixes):** 30 minutes
- **Phase 2 (Error Suppression):** 15 minutes
- **Phase 3 (Debug Logging):** 20 minutes
- **Phase 4 (Testing):** 60 minutes
- **Phase 5 (Validation):** 30 minutes
- **Phase 6 (Cleanup):** 15 minutes

**Total:** ~2.5 hours

---

## Notes

- Always test on clean system (remove existing installation)
- Keep log file open in separate terminal during testing
- Take screenshots of dialogs for documentation
- Document any new issues found during testing
- Update `dialog-logic.md` with any new findings

---

## Related Documents

- `dialog-logic.md` - Comprehensive analysis of all dialog issues
- `build-install-app.sh` - Main installer script
- `build-all.sh` - Master build script
- `/Users/Shared/AIPrivateSearch/logs/install.log` - Installation log file

---

**Last Updated:** 2024
**Status:** Ready for Implementation
