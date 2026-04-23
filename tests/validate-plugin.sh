#!/usr/bin/env bash
# Validates agent-orchestrator plugin structure.
# Exit codes: 0 = all pass, 1 = failures found
# Inspired by agentic-os/tests/validate-plugin.sh (simpler — single skill plugin).

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0
TESTS=0
PASSED=0

pass() { TESTS=$((TESTS + 1)); PASSED=$((PASSED + 1)); echo "  PASS: $1"; }
fail() { TESTS=$((TESTS + 1)); ERRORS=$((ERRORS + 1)); echo "  FAIL: $1"; }

# Convert MSYS/Git-Bash style /c/… paths to Windows C:/… when python is the
# native Windows Python (cannot read /c/… paths). Harmless elsewhere.
winpath() {
    local p="$1"
    if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
        printf '%s:/%s' "${BASH_REMATCH[1]^^}" "${BASH_REMATCH[2]}"
    else
        printf '%s' "$p"
    fi
}

check_json() {
    python -c "import json,sys; json.loads(open(sys.argv[1],encoding='utf-8').read())" "$(winpath "$1")" 2>/dev/null
}

check_json_has() {
    python -c "import json,sys; d=json.loads(open(sys.argv[1],encoding='utf-8').read()); sys.exit(0 if sys.argv[2] in d else 1)" "$(winpath "$1")" "$2" 2>/dev/null
}

# Read a nested key like "plugins[0].source.source" from a JSON file.
json_get() {
    local file="$1"
    local path="$2"
    python -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    d = json.load(f)
for part in sys.argv[2].split('.'):
    if '[' in part:
        name, idx = part.split('[')
        idx = int(idx.rstrip(']'))
        d = d[name][idx] if name else d[idx]
    else:
        d = d[part]
print(d)
" "$(winpath "$file")" "$path" 2>/dev/null
}

echo "=== agent-orchestrator Plugin Validation ==="

# 1. plugin.json
echo ""
echo "-- plugin.json --"
MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"
if [ -f "$MANIFEST" ]; then
    pass "plugin.json exists in .claude-plugin/"
    if check_json "$MANIFEST"; then
        pass "plugin.json is valid JSON"
        for field in name version description; do
            if check_json_has "$MANIFEST" "$field"; then
                pass "plugin.json has '$field'"
            else
                fail "plugin.json missing '$field'"
            fi
        done
    else
        fail "plugin.json is not valid JSON"
    fi
else
    fail "plugin.json missing at .claude-plugin/plugin.json (Variante-2 layout required)"
fi

# 2. marketplace.json
echo ""
echo "-- marketplace.json --"
MKT="$PLUGIN_ROOT/.claude-plugin/marketplace.json"
if [ -f "$MKT" ]; then
    pass "marketplace.json exists"
    if check_json "$MKT"; then
        pass "marketplace.json is valid JSON"
        # source.source should be github (not url)
        SRC=$(json_get "$MKT" "plugins[0].source.source")
        if [ "$SRC" = "github" ]; then
            pass "marketplace.json uses source.source: github (preferred)"
        elif [ "$SRC" = "git" ] || [ "$SRC" = "url" ]; then
            pass "marketplace.json uses source.source: $SRC (accepted but github is preferred)"
        else
            fail "marketplace.json source.source must be github/git/url, got: $SRC"
        fi
    else
        fail "marketplace.json is not valid JSON"
    fi
else
    fail "marketplace.json missing"
fi

# 3. SKILL.md
echo ""
echo "-- SKILL.md --"
SKILL="$PLUGIN_ROOT/skills/agent-orchestrator/SKILL.md"
if [ -f "$SKILL" ]; then
    pass "SKILL.md exists"
    if head -1 "$SKILL" | grep -q "^---$"; then
        pass "SKILL.md has YAML frontmatter"
    else
        fail "SKILL.md does not start with YAML frontmatter (---)"
    fi
    # name field
    if awk '/^---$/{c++; next} c==1 && /^name:/' "$SKILL" | grep -q "agent-orchestrator"; then
        pass "SKILL.md frontmatter has name: agent-orchestrator"
    else
        fail "SKILL.md frontmatter missing or wrong name"
    fi
    # user_invocable
    if grep -q "^user_invocable:" "$SKILL"; then
        pass "SKILL.md has user_invocable field"
    else
        fail "SKILL.md missing user_invocable field"
    fi
    # metadata block
    if grep -q "^metadata:" "$SKILL"; then
        pass "SKILL.md has metadata block"
    else
        fail "SKILL.md missing metadata block"
    fi
    # English trigger phrases (mandatory for Claude Code skills — tests in other
    # plugins enforce this; keep it consistent)
    if grep -qE "Trigger phrases:|\"orchestrate|\"big project|\"full auto" "$SKILL"; then
        pass "SKILL.md has English trigger phrases"
    else
        fail "SKILL.md missing English trigger phrases in description"
    fi
    # When NOT to Use section (prevents over-triggering)
    if grep -qE "When NOT to Use|When not to use" "$SKILL"; then
        pass "SKILL.md has 'When NOT to Use' section"
    else
        fail "SKILL.md missing 'When NOT to Use' section"
    fi
    # No stale Codex model names (5.3, 5.2, 5.1 without gpt- prefix)
    if grep -qE "Codex 5\.[123]([^.]|$)" "$SKILL"; then
        fail "SKILL.md references obsolete Codex model names (5.3/5.2/5.1) — use gpt-5-4 / gpt-5.4-mini / gpt-5.3-codex-spark"
    else
        pass "SKILL.md uses current Codex model nomenclature"
    fi
    # No Chrome-MCP notebooklm references (must use Python API user-skill)
    if grep -qE "notebooklm:(chat|navigate|add-source|studio|create-notebook)" "$SKILL"; then
        fail "SKILL.md references deprecated notebooklm:* plugin commands — use notebooklm CLI (notebooklm-py) instead"
    else
        pass "SKILL.md does not reference deprecated notebooklm:* plugin commands"
    fi
else
    fail "SKILL.md missing at skills/agent-orchestrator/SKILL.md"
fi

# 4. README.md — correct install syntax
echo ""
echo "-- README.md --"
README="$PLUGIN_ROOT/README.md"
if [ -f "$README" ]; then
    pass "README.md exists"
    if grep -q "claude plugin marketplace add" "$README"; then
        pass "README.md uses correct 'claude plugin marketplace add' install syntax"
    else
        fail "README.md missing 'claude plugin marketplace add' install instruction"
    fi
    # Old wrong syntax should not be present
    if grep -qE "claude plugin install https?://" "$README"; then
        fail "README.md uses obsolete 'claude plugin install <URL>' syntax — not supported by CLI"
    else
        pass "README.md does not use obsolete install-from-URL syntax"
    fi
else
    fail "README.md missing"
fi

# 5. .gitignore — must exclude settings.local.json
echo ""
echo "-- .gitignore --"
GI="$PLUGIN_ROOT/.gitignore"
if [ -f "$GI" ]; then
    pass ".gitignore exists"
    if grep -q "settings.local.json" "$GI"; then
        pass ".gitignore excludes settings.local.json (prevents secret leaks)"
    else
        fail ".gitignore does not exclude settings.local.json"
    fi
else
    fail ".gitignore missing"
fi

# Summary
echo ""
echo "=== Results: $PASSED/$TESTS passed, $ERRORS failures ==="
if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0
