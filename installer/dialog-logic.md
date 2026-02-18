# Dialog System Analysis - AIPrivateSearch Installer

## Overview
The installer uses AppleScript dialogs for user interaction. All dialogs are embedded in a bash script that gets built into the .app bundle.

## Dialog Functions

### 1. `notify(title, message)`
**Location:** Line 164  
**Purpose:** Show macOS notification  
**Implementation:**
```bash
osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null
```
**Usage:** Not currently used in script

---

### 2. `show_progress(message)`
**Location:** Line 171  
**Purpose:** Show cumulative progress dialog (only if SHOW_DETAILS=Yes)  
**Implementation:**
```bash
if [ "$SHOW_DETAILS" = "Yes" ]; then
    PROGRESS_LOG="${PROGRESS_LOG}${message}\\n\\n"
    osascript <<-APPLESCRIPT 2>/dev/null
        tell application "System Events"
            activate
            display dialog "$PROGRESS_LOG" with title "AIPrivateSearch Installer" 
                buttons {"Continue"} default button "Continue" with icon note
        end tell
    APPLESCRIPT
fi
```
**Key Points:**
- Only shows if user selected "Yes" for detailed messages
- Accumulates messages in PROGRESS_LOG variable
- Single "Continue" button
- Errors suppressed with `2>/dev/null`

**Called at:**
- Line 289: Installation started
- Line 338: Architecture detected
- Line 423: Node.js installed
- Line 577: Ollama installed
- Line 641: Chrome installed
- Line 835: Dependencies installed
- Line 934: Installation complete

---

### 3. `show_dialog(title, message, type)`
**Location:** Line 235  
**Purpose:** Show simple dialog with OK button  
**Implementation:**
```bash
osascript <<-APPLESCRIPT 2>/dev/null || echo "$message"
    tell application "System Events"
        activate
        display dialog "$message" with title "$title" 
            buttons {"OK"} default button "OK" with icon $type
    end tell
APPLESCRIPT
```
**Parameters:**
- `type`: informational, caution, stop, note

**Called at:**
- Line 253: Administrator access required
- Line 871: Step 7 complete
- Line 918: Installation error
- Line 944: Installation complete

---

## Direct osascript Calls (Not in Functions)

### Menu Dialogs

**Line 88-96:** Main menu (already installed)
```bash
CHOICE=$(osascript <<-APPLESCRIPT
    tell application "System Events"
        activate
        set choice to button returned of (display dialog 
            "AIPrivateSearch is already installed.\n\nWhat would you like to do?" 
            buttons {"Cancel", "Update", "Start App"} 
            default button "Start App" 
            with title "AIPrivateSearch Manager" 
            with icon note)
    end tell
    return choice
APPLESCRIPT
)
```

**Line 100-108:** Update submenu
```bash
UPDATE_CHOICE=$(osascript <<-APPLESCRIPT
    tell application "System Events"
        activate
        set choice to button returned of (display dialog 
            "Update Options" 
            buttons {"Cancel", "Update", "Uninstall"} 
            default button "Update" 
            with title "AIPrivateSearch Manager" 
            with icon note)
    end tell
    return choice
APPLESCRIPT
)
```

**Line 129-137:** Install menu (not installed)
```bash
CHOICE=$(osascript <<-APPLESCRIPT 2>/dev/null
    tell application "System Events"
        activate
        set choice to button returned of (display dialog 
            "AIPrivateSearch is not installed.\n\nWould you like to install it now?" 
            buttons {"Cancel", "Install"} 
            default button "Install" 
            with title "AIPrivateSearch Installer" 
            with icon note)
    end tell
    return choice
APPLESCRIPT
)
```

**Line 191-199:** Show detailed messages prompt
```bash
SHOW_DETAILS=$(osascript <<-APPLESCRIPT 2>/dev/null
    tell application "System Events"
        activate
        display dialog "Show detailed installation messages in Terminal?..." 
            buttons {"No", "Yes"} 
            default button "Yes" 
            with title "AIPrivateSearch Installer" 
            with icon note
    end tell
    return button returned of result
APPLESCRIPT
)
```

**Line 264:** Password prompt
```bash
ADMIN_PASSWORD=$(osascript -e 'display dialog "Enter your administrator password:" 
    default answer "" with hidden answer' 
    -e 'text returned of result' 2>/dev/null)
```

**Line 781-785:** UPDATE_MODE test dialogs (PROBLEM AREA)
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

---

## Variable Scope Issues

### UPDATE_MODE Variable
**Declared:** Line 79 (global): `UPDATE_MODE="false"`  
**Set to true:** Line 111 (inside nested case statement)  
**Used at:** Lines 717, 744, 755, 766, 778, 780, 946

**PROBLEM:** The variable is set inside a case statement but needs to persist to later code sections.

### SHOW_DETAILS Variable
**Set:** Line 191 (from dialog)  
**Used:** Line 171 (in show_progress function)  
**Scope:** Global, works correctly

---

## Error Suppression

Most dialogs use `2>/dev/null` to suppress errors:
- Prevents error messages if dialog fails
- Makes debugging difficult
- Hides why dialogs might not appear

**Lines with error suppression:**
- 129, 167, 175, 191, 202, 240, 264

**Lines with `|| true`:**
- 781, 784 (allows script to continue even if dialog fails)

---

## Dialog Flow for All Choices

### Flow 1: Fresh Install (Not Installed)
1. **Line 87:** Check if `/Users/Shared/AIPrivateSearch/repo/aiprivatesearch` exists → NO
2. **Line 129:** Show "Not installed" dialog with buttons: Cancel, Install
3. **Line 139:** If user clicks "Cancel" → exit
4. **Line 144:** If user clicks "Install" → continue to installation
5. **Line 147:** Falls through to installation logic (DMG detection, etc.)
6. **UPDATE_MODE:** Remains "false" (default)
7. **Line 781:** Shows "UPDATE_MODE=EMPTY" dialog
8. **Line 946:** Shows "installed successfully" message

---

### Flow 2: Update (Already Installed)
1. **Line 87:** Check if `/Users/Shared/AIPrivateSearch/repo/aiprivatesearch` exists → YES
2. **Line 88:** Show main menu with buttons: Cancel, Update, Start App
3. **User selects "Update"**
4. **Line 99:** Set `echo "Update menu selected"`
5. **Line 100:** Show update submenu with buttons: Cancel, Update, Uninstall
6. **User selects "Update"**
7. **Line 109:** Set `echo "Update selected - starting update process"`
8. **Line 111:** Set `UPDATE_MODE="true"`
9. **Line 113:** Comment: "Fall through to installation logic"
10. **Line 114:** `;;` ends inner case (UPDATE_CHOICE)
11. **Line 115:** Comment: "Continue to installation below"
12. **Line 116:** `;;` ends outer case (CHOICE for "Update")
13. **Line 117-126:** Other case branches (Start App, Cancel) - NOT EXECUTED
14. **Line 127:** `esac` ends outer case statement
15. **Line 128:** `else` branch (not installed) - NOT EXECUTED
16. **Line 147:** Falls through to installation logic
17. **UPDATE_MODE:** Should be "true"
18. **Line 781:** Should show "UPDATE_MODE=TRUE" dialog
19. **Line 946:** Should show "updated successfully" message

**CRITICAL ISSUE:** After line 116 `;;`, the script should continue to line 127 `esac`, then fall through to line 147. But UPDATE_MODE may not persist.

---

### Flow 3: Start App (Already Installed)
1. **Line 87:** Check if installed → YES
2. **Line 88:** Show main menu with buttons: Cancel, Update, Start App
3. **User selects "Start App"**
4. **Line 118:** Set `echo "Start App selected - not implemented yet"`
5. **Line 119:** Show "coming soon" dialog
6. **Line 120:** `exit 0` - SCRIPT ENDS
7. **Does not reach installation logic**

---

### Flow 4: Uninstall (From Update Menu)
1. **Line 87:** Check if installed → YES
2. **Line 88:** Show main menu → User selects "Update"
3. **Line 100:** Show update submenu with buttons: Cancel, Update, Uninstall
4. **User selects "Uninstall"**
5. **Line 117:** Set `echo "Uninstall selected - not implemented yet"`
6. **Line 118:** Show "coming soon" dialog
7. **Line 119:** `exit 0` - SCRIPT ENDS
8. **Does not reach installation logic**

---

### Flow 5: Cancel (Any Menu)
1. **User clicks "Cancel" on any dialog**
2. **Line 121-124 or 139-142:** Set `echo "Cancelled"`
3. **Line 122 or 140:** `exit 0` - SCRIPT ENDS
4. **Does not reach installation logic**

---

## Case Statement Structure

```bash
if [ -d "$APP_SUPPORT/repo/aiprivatesearch" ]; then
    # ALREADY INSTALLED
    CHOICE=$(osascript...) # Main menu
    
    case "$CHOICE" in
        "Update")
            UPDATE_CHOICE=$(osascript...) # Update submenu
            case "$UPDATE_CHOICE" in
                "Update")
                    UPDATE_MODE="true"
                    # Fall through
                    ;;
                "Uninstall")
                    exit 0
                    ;;
                *)
                    exit 0
                    ;;
            esac
            # Continue to installation below
            ;;
        "Start App")
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
else
    # NOT INSTALLED
    CHOICE=$(osascript...) # Install menu
    if [ "$CHOICE" != "Install" ]; then
        exit 0
    fi
fi

# INSTALLATION LOGIC STARTS HERE (Line 147+)
# Both Update and Install reach this point
# UPDATE_MODE should be "true" for Update, "false" for Install
```

---

## 🚨 CRITICAL BUG FOUND 🚨

### Missing `esac` Statement

**Location:** Lines 85-128

**Problem:** The outer `case "$CHOICE"` statement is **NEVER CLOSED** with `esac`!

**Current Structure (BROKEN):**
```bash
if [ -d "$APP_SUPPORT/repo/aiprivatesearch" ]; then
    CHOICE=$(osascript...)  # Line 88
    
    case "$CHOICE" in      # Line 98 - CASE OPENS
        "Update")           # Line 99
            # nested case for UPDATE_CHOICE
            esac            # Line 125 - closes INNER case only
            ;;
        # ❌ MISSING: "Start App" case
        # ❌ MISSING: "*" default case  
        # ❌ MISSING: esac to close outer case!
else                        # Line 128 - jumps to else WITHOUT closing case!
    # Not installed
fi
```

**What Actually Happens:**
1. Line 98: `case "$CHOICE"` opens
2. Line 99-126: "Update" case executes
3. Line 126: `;;` ends "Update" case
4. **Line 127: Should have `esac` but it's MISSING**
5. Line 128: Script jumps to `else` with unclosed case statement

**Result:** Invalid bash syntax. The case statement is incomplete.

**Why Script Still Runs:** Bash may be interpreting the structure differently or the `else` is implicitly closing something, but the logic is broken.

**Why UPDATE_MODE Doesn't Show:** After the "Update" case ends at line 126, there's no proper exit from the case statement. The script flow is undefined.

---

## Other Structural Issues Found

### 1. Missing Case Branches
The outer case statement only has ONE branch ("Update") but should have:
- "Update" branch ✅ (exists)
- "Start App" branch ❌ (missing)
- "*" default/cancel branch ❌ (missing)

### 2. Inconsistent Error Handling
- Some osascript calls use `2>/dev/null` (lines 129, 191, 202)
- Some use `|| true` (lines 781, 784)
- Some have no error handling
- **Recommendation:** Be consistent

### 3. Variable Scope Confusion
- `UPDATE_MODE` declared at line 79 (global)
- Set at line 111 (inside nested case)
- Used at line 781 (after case should close)
- **Issue:** With broken case structure, variable scope is unpredictable

### 4. If Statement Balance
Checked all if/fi pairs:
- Line 87: `if [ -d ...` → Line 146: `fi` ✅ BALANCED
- Line 139: `if [ "$CHOICE" != ...` → Line 142: `fi` ✅ BALANCED
- Line 171: `if [ "$SHOW_DETAILS" ...` → Line 180: `fi` ✅ BALANCED
- All other if statements: ✅ BALANCED

### 5. Loop Statements
No `for`, `while`, or `until` loops found in the menu section.

---

## Fix Required

**Add missing case branches and close the case statement:**

```bash
if [ -d "$APP_SUPPORT/repo/aiprivatesearch" ]; then
    CHOICE=$(osascript...)
    
    case "$CHOICE" in
        "Update")
            UPDATE_CHOICE=$(osascript...)
            case "$UPDATE_CHOICE" in
                "Update")
                    UPDATE_MODE="true"
                    ;;
                "Uninstall")
                    osascript -e 'display dialog "Uninstall coming soon"'
                    exit 0
                    ;;
                *)
                    echo "Cancelled"
                    exit 0
                    ;;
            esac
            # Continue to installation
            ;;
        "Start App")
            osascript -e 'display dialog "Start App coming soon"'
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
``` 0
                    ;;
                *)
                    exit 0
                    ;;
            esac
            # Continue to installation below
            ;;
        "Start App")
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
else
    # NOT INSTALLED
    CHOICE=$(osascript...) # Install menu
    if [ "$CHOICE" != "Install" ]; then
        exit 0
    fi
fi

# INSTALLATION LOGIC STARTS HERE (Line 147+)
# Both Update and Install reach this point
# UPDATE_MODE should be "true" for Update, "false" for Install
```

---

## Variable Persistence Test

**After line 116 `;;`**, the script should:
1. Exit the inner case (UPDATE_CHOICE)
2. Exit the outer case (CHOICE)
3. Continue to line 147 (installation logic)
4. UPDATE_MODE should still be "true"

**Test needed:** Add echo immediately after line 127 `esac`:
```bash
echo "[AFTER CASE] UPDATE_MODE=$UPDATE_MODE"
```

---

## Recommendations

1. **Remove error suppression** temporarily to see actual errors
2. **Add echo statements** before/after each dialog to trace execution
3. **Check case statement structure** - ensure Update path doesn't exit early
4. **Test UPDATE_MODE value** with simple echo right after it's set
5. **Verify script execution** reaches line 781

---

## Test Commands

Check if dialog code exists in built app:
```bash
grep -c "UPDATE_MODE=TRUE" build/AIPrivateSearch.app/Contents/MacOS/AIPrivateSearch
```

Check if UPDATE_MODE is declared:
```bash
grep "UPDATE_MODE=" build/AIPrivateSearch.app/Contents/MacOS/AIPrivateSearch | head -5
```

Run app and check log:
```bash
tail -f /Users/Shared/AIPrivateSearch/logs/install.log
```


---

## AppleScript Syntax Analysis

### Does AppleScript Fail Silently?

**YES** - AppleScript errors are suppressed in this script due to:
1. `2>/dev/null` redirects stderr to nowhere (lines 129, 167, 175, 191, 202, 240, 264)
2. `|| true` forces success even if osascript fails (lines 781, 784)

**Result:** If there's an AppleScript syntax error, you'll never see it.

---

### AppleScript Syntax Errors Found

#### 1. **Line 781-784: Single-line osascript with `-e` flag**

**Current Code:**
```bash
osascript -e 'display dialog "Config files preserved\nData files preserved" 
    with title "UPDATE_MODE=TRUE" 
    buttons {"Continue"} default button "Continue"' || true
```

**Problem:** Multi-line string in single `-e` flag. The newline after `preserved"` breaks the command.

**Correct Syntax:**
```bash
# Option 1: All on one line
osascript -e 'display dialog "Config files preserved\nData files preserved" with title "UPDATE_MODE=TRUE" buttons {"Continue"} default button "Continue"' || true

# Option 2: Use heredoc (like other dialogs)
osascript <<-APPLESCRIPT || true
    display dialog "Config files preserved" & linefeed & "Data files preserved" \
        with title "UPDATE_MODE=TRUE" \
        buttons {"Continue"} default button "Continue"
APPLESCRIPT
```

**Why It Fails:**
- Bash sees the newline and thinks the command ended
- The rest is interpreted as a new command or syntax error
- `|| true` hides the error
- Dialog never appears

---

### Summary of AppleScript Issues

| Line | Issue | Severity | Fix |
|------|-------|----------|-----|
| 781-784 | Multi-line string in single `-e` flag | **CRITICAL** | Put all on one line or use heredoc |
| All | Error suppression with `2>/dev/null` | High | Remove temporarily for debugging |
| 781, 784 | `|| true` hides failures | High | Remove temporarily for debugging |

---

### Test Command

Test the dialog syntax directly in terminal:
```bash
osascript -e 'display dialog "Config files preserved" with title "UPDATE_MODE=TRUE" buttons {"Continue"} default button "Continue"'
```

If this works, the syntax is correct. If it fails, you'll see the actual error.


---

## Making AppleScript Errors Visible

### Current State (Errors Hidden)
```bash
osascript -e '...' 2>/dev/null  # Hides stderr
osascript <<-APPLESCRIPT 2>/dev/null  # Hides stderr
osascript -e '...' || true  # Forces success
```

### Modified for Debugging (Errors Shown)

**Option 1: Remove error suppression**
```bash
# Change this:
osascript -e 'display dialog "..." with title "..."' || true

# To this:
osascript -e 'display dialog "..." with title "..."'
# Now errors will show in terminal and script will exit on failure
```

**Option 2: Capture and display errors**
```bash
# Capture stderr to variable
ERROR=$(osascript -e 'display dialog "..." with title "..."' 2>&1)
if [ $? -ne 0 ]; then
    echo "AppleScript Error: $ERROR"
    osascript -e 'display dialog "AppleScript Error:\n\n'"$ERROR"'" buttons {"OK"} with icon stop'
    exit 1
fi
```

**Option 3: Log errors but continue**
```bash
osascript -e 'display dialog "..." with title "..."' 2>> "$LOG_FILE" || {
    echo "AppleScript dialog failed - check log" >> "$LOG_FILE"
}
```

### Recommended Debugging Changes

**For lines 781-784, change:**
```bash
if [ "$UPDATE_MODE" = "true" ]; then
    osascript -e 'display dialog "Config files preserved\nData files preserved" 
        with title "UPDATE_MODE=TRUE" 
        buttons {"Continue"} default button "Continue"' || true
```

**To:**
```bash
if [ "$UPDATE_MODE" = "true" ]; then
    echo "[DEBUG] Attempting to show UPDATE_MODE=TRUE dialog"
    if ! osascript -e 'display dialog "Config files preserved" with title "UPDATE_MODE=TRUE" buttons {"Continue"} default button "Continue"'; then
        echo "[ERROR] Dialog failed with exit code $?"
        echo "[ERROR] This means AppleScript syntax error or System Events unavailable"
    fi
```

This will:
1. Show debug message in log
2. Show actual AppleScript errors
3. Show exit code if it fails
4. Continue script execution

### Quick Test Script

Create `test-dialog.sh`:
```bash
#!/bin/bash
echo "Testing AppleScript dialog..."
osascript -e 'display dialog "Test" with title "DEBUG" buttons {"OK"} default button "OK"'
echo "Exit code: $?"
```

Run: `bash test-dialog.sh`
- Exit code 0 = success
- Exit code ≠ 0 = error (will show error message)


---

## Cancel Button Issue

### Problem Statement
The `show_progress()` function only shows a "Continue" button. Users cannot cancel during installation/update progress dialogs.

### Current Implementation (Line 171-180)
```bash
show_progress() {
    if [ "$SHOW_DETAILS" = "Yes" ]; then
        PROGRESS_LOG="${PROGRESS_LOG}${message}\\n\\n"
        osascript <<-APPLESCRIPT 2>/dev/null
            tell application "System Events"
                activate
                display dialog "$PROGRESS_LOG" with title "AIPrivateSearch Installer" 
                    buttons {"Continue"} default button "Continue" with icon note
            end tell
        APPLESCRIPT
    fi
}
```

**Issue:** Only one button: `{"Continue"}`

### Why Cancel Button Doesn't Work

**Attempt 1: Add Cancel button**
```bash
buttons {"Cancel", "Continue"} default button "Continue"
```

**Problem:** If user clicks "Cancel", the dialog returns "Cancel" but the function doesn't check the return value. Script continues anyway.

**Attempt 2: Check button returned**
```bash
BUTTON=$(osascript <<-APPLESCRIPT
    ...
    return button returned of result
APPLESCRIPT
)
if [ "$BUTTON" = "Cancel" ]; then
    exit 0
fi
```

**Problem:** `show_progress()` is called multiple times during installation. Adding exit logic to the function would require refactoring all 7+ call sites.

### Root Cause

The `show_progress()` function is designed as **informational only**, not interactive:
1. It accumulates messages in `PROGRESS_LOG`
2. Shows cumulative progress
3. Doesn't return values
4. Doesn't handle user choice

### Solutions

#### Solution 1: Make show_progress() Interactive (Complex)
```bash
show_progress() {
    if [ "$SHOW_DETAILS" = "Yes" ]; then
        PROGRESS_LOG="${PROGRESS_LOG}${message}\\n\\n"
        BUTTON=$(osascript <<-APPLESCRIPT
            tell application "System Events"
                activate
                set choice to button returned of (display dialog "$PROGRESS_LOG" \
                    with title "AIPrivateSearch Installer" \
                    buttons {"Cancel", "Continue"} \
                    default button "Continue" \
                    with icon note)
            end tell
            return choice
        APPLESCRIPT
        )
        if [ "$BUTTON" = "Cancel" ]; then
            osascript -e 'display dialog "Installation cancelled by user" buttons {"OK"} with icon stop'
            exit 1
        fi
    fi
}
```

**Pros:** Cancel works everywhere  
**Cons:** Requires testing all 7+ call sites

#### Solution 2: Remove Progress Dialogs (Simple)
```bash
show_progress() {
    # Do nothing - user watches terminal log instead
    return 0
}
```

**Pros:** Simple, no dialogs to break  
**Cons:** Less user-friendly

#### Solution 3: Progress Dialogs Without Buttons (Recommended)
```bash
show_progress() {
    if [ "$SHOW_DETAILS" = "Yes" ]; then
        PROGRESS_LOG="${PROGRESS_LOG}${message}\\n\\n"
        osascript <<-APPLESCRIPT 2>/dev/null &
            tell application "System Events"
                activate
                display dialog "$PROGRESS_LOG" \
                    with title "AIPrivateSearch Installer" \
                    giving up after 3 \
                    with icon note
            end tell
        APPLESCRIPT
    fi
}
```

**Changes:**
- Removed `buttons` - dialog auto-dismisses
- Added `giving up after 3` - closes after 3 seconds
- Added `&` - runs in background, doesn't block

**Pros:** Non-blocking, informational only  
**Cons:** No user interaction

#### Solution 4: Only Add Cancel to Critical Dialogs
Don't modify `show_progress()`. Instead, add Cancel button only to the UPDATE_MODE dialog (line 781):

```bash
if [ "$UPDATE_MODE" = "true" ]; then
    BUTTON=$(osascript <<-APPLESCRIPT
        display dialog "Config files preserved" & linefeed & "Data files preserved" \
            with title "UPDATE_MODE=TRUE" \
            buttons {"Cancel", "Continue"} \
            default button "Continue"
    APPLESCRIPT
    )
    if [ "$BUTTON" = "Cancel" ]; then
        echo "Update cancelled by user"
        exit 0
    fi
fi
```

**Pros:** Targeted fix, minimal changes  
**Cons:** Only works for this one dialog

### Recommendation

**Use Solution 4** - Add Cancel button with exit handling only to the UPDATE_MODE dialog at line 781. This is:
- Minimal code change
- Addresses the specific request
- Doesn't break existing progress dialogs
- Easy to test

The `show_progress()` function should remain informational-only since it's called during long-running operations where cancellation would leave the system in an inconsistent state.
