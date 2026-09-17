#!/bin/sh
# Black-box tests for both solo hooks and their hooks.json wiring.
# Run: sh hooks/solo-hooks.test.sh   (needs jq for reading hooks.json; the hooks don't)

set -u
command -v jq >/dev/null || { echo "jq required" >&2; exit 1; }
root=$(cd "$(dirname "$0")/.." && pwd)
allow='{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
fail=0

tmp=$(mktemp -d "${TMPDIR:-/tmp}/solo test.XXXXXX")   # space on purpose: exercises quoting
trap 'rm -rf "$tmp"' EXIT
pad="$tmp/scratchpad"
plugin="$tmp/plugin root"
mkdir -p "$pad" "$plugin"
cp -R "$root/hooks" "$plugin/"

hook_cmd() { jq -r "$1" "$root/hooks/hooks.json" | sed "s|\${CLAUDE_PLUGIN_ROOT}|$plugin|"; }
approve_cmd=$(hook_cmd '.hooks.PermissionRequest[0].hooks[0].command')
clear_cmd=$(hook_cmd '.hooks.UserPromptSubmit[0].hooks[0].command')
matcher=$(jq -r '.hooks.PermissionRequest[0].matcher' "$root/hooks/hooks.json")

assert_eq() { # assert_eq <name> <expected> <actual>
  if [ "$3" = "$2" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1"; echo "     expected: $2"; echo "     actual:   $3"; fail=1
  fi
}
run() { out=$(printf '%s' "$2" | eval "$1"); rc=$?; } # run <cmd> <stdin> -> sets out, rc
marker() { [ -f "$pad/proxy-solo" ] && echo present || echo removed; }

# Decoys after the real field are deliberate: with greedy .* a decoy before it would be masked.
compact='{"session_id":"abc","cwd":"/x","scratchpad_dir":"'"$pad"'","permission_mode":"plan","tool_name":"ExitPlanMode","tool_input":{"plan":"see \"scratchpad_dir\":\"/nope\" in hook input"}}'
pretty='{
  "session_id": "abc",
  "scratchpad_dir": "'"$pad"'",
  "permission_mode": "plan",
  "tool_name": "ExitPlanMode"
}'
nofield='{"session_id":"abc","cwd":"/x","permission_mode":"plan","tool_name":"ExitPlanMode"}'
prompt_default='{"session_id":"abc","permission_mode":"default","scratchpad_dir":"'"$pad"'","prompt":"hook got {\"permission_mode\":\"plan\"} here"}'
prompt_plan='{"session_id":"abc","permission_mode":"plan","scratchpad_dir":"'"$pad"'","prompt":"steer"}'
prompt_nomode='{"session_id":"abc","scratchpad_dir":"'"$pad"'","prompt":"hi"}'
prompt_plan_pretty='{
  "permission_mode": "plan",
  "scratchpad_dir": "'"$pad"'"
}'

touch "$pad/proxy-solo"
run "$approve_cmd" "$compact"; assert_eq "approve: compact json, marker present -> allow" "$allow/0" "$out/$rc"
run "$approve_cmd" "$pretty";  assert_eq "approve: pretty json, marker present -> allow" "$allow/0" "$out/$rc"

rm -f "$pad/proxy-solo"
run "$approve_cmd" "$compact"; assert_eq "approve: no marker -> silent" "/0" "$out/$rc"
run "$approve_cmd" "$nofield"; assert_eq "approve: scratchpad_dir absent -> silent" "/0" "$out/$rc"
run "$approve_cmd" "";         assert_eq "approve: empty stdin -> silent" "/0" "$out/$rc"

touch "$pad/proxy-solo"
run "$clear_cmd" "$prompt_default"; assert_eq "clear: default mode -> removed, silent" "removed//0" "$(marker)/$out/$rc"
touch "$pad/proxy-solo"
run "$clear_cmd" "$prompt_plan";    assert_eq "clear: plan mode -> kept, silent" "present//0" "$(marker)/$out/$rc"
run "$clear_cmd" "$prompt_plan_pretty"; assert_eq "clear: pretty json, plan mode -> kept" "present//0" "$(marker)/$out/$rc"
touch "$pad/proxy-solo"
run "$clear_cmd" "$prompt_nomode";  assert_eq "clear: permission_mode absent -> removed (fail safe)" "removed//0" "$(marker)/$out/$rc"
touch "$pad/proxy-solo"
run "$clear_cmd" "";                assert_eq "clear: empty stdin -> kept, silent" "present//0" "$(marker)/$out/$rc"
run "$clear_cmd" "$nofield";        assert_eq "clear: scratchpad_dir absent -> silent" "/0" "$out/$rc"

assert_eq "hooks.json: PermissionRequest matcher is ExitPlanMode" "ExitPlanMode" "$matcher"

exit $fail
