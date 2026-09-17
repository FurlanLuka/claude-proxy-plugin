#!/bin/sh
# Black-box tests for the three solo hooks and their hooks.json wiring.
# Run: sh hooks/solo-hooks.test.sh   (needs jq for reading hooks.json; the hooks don't)

set -u
command -v jq >/dev/null || { echo "jq required" >&2; exit 1; }
root=$(cd "$(dirname "$0")/.." && pwd)
allow='{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
fail=0

tmp=$(mktemp -d "${TMPDIR:-/tmp}/solo test.XXXXXX")   # space on purpose: exercises quoting
plugin="$tmp/plugin root"
mkdir -p "$plugin"
cp -R "$root/hooks" "$plugin/"
sid="test-$$-$(date +%s)"
marker="/tmp/claude-proxy-solo-$sid"
trap 'rm -rf "$tmp" "$marker"' EXIT

hook_cmd() { jq -r "$1" "$root/hooks/hooks.json" | sed "s|\${CLAUDE_PLUGIN_ROOT}|$plugin|"; }
arm_cmd=$(hook_cmd '.hooks.PreToolUse[0].hooks[0].command')
approve_cmd=$(hook_cmd '.hooks.PermissionRequest[0].hooks[0].command')
clear_cmd=$(hook_cmd '.hooks.UserPromptSubmit[0].hooks[0].command')
arm_matcher=$(jq -r '.hooks.PreToolUse[0].matcher' "$root/hooks/hooks.json")
approve_matcher=$(jq -r '.hooks.PermissionRequest[0].matcher' "$root/hooks/hooks.json")

assert_eq() { # assert_eq <name> <expected> <actual>
  if [ "$3" = "$2" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1"; echo "     expected: $2"; echo "     actual:   $3"; fail=1
  fi
}
run() { out=$(printf '%s' "$2" | eval "$1"); rc=$?; } # run <cmd> <stdin> -> sets out, rc
state() { [ -f "$marker" ] && echo present || echo removed; }

# Decoys are JSON-escaped (\"key\"), so they can't match regardless of position; they prove the pattern
# doesn't see through escaping.
compact='{"session_id":"'"$sid"'","cwd":"/x","permission_mode":"plan","tool_name":"ExitPlanMode","tool_input":{"plan":"see \"session_id\":\"nope\" in hook input"}}'
pretty='{
  "session_id": "'"$sid"'",
  "permission_mode": "plan",
  "tool_name": "ExitPlanMode"
}'
nosid='{"cwd":"/x","permission_mode":"plan","tool_name":"ExitPlanMode"}'
badsid='{"session_id":"../../etc/passwd","permission_mode":"plan","tool_name":"ExitPlanMode"}'
othersid='{"session_id":"'"$sid"'-other","permission_mode":"plan","tool_name":"ExitPlanMode"}'
prompt_auto='{"session_id":"'"$sid"'","permission_mode":"auto","prompt":"hook got {\"permission_mode\":\"plan\"} here"}'
prompt_plan='{"session_id":"'"$sid"'","permission_mode":"plan","prompt":"steer"}'
prompt_plan_pretty='{
  "permission_mode": "plan",
  "session_id": "'"$sid"'"
}'
prompt_nomode='{"session_id":"'"$sid"'","prompt":"hi"}'
skill_solo='{"session_id":"'"$sid"'","tool_name":"Skill","tool_input":{"skill":"proxy:solo","args":"fix the thing"}}'
skill_pair='{"session_id":"'"$sid"'","tool_name":"Skill","tool_input":{"skill":"proxy:pair","args":"see \"skill\":\"proxy:solo\""}}'
skill_other='{"session_id":"'"$sid"'","tool_name":"Skill","tool_input":{"skill":"proxy:qa-plan","args":"x"}}'
skill_other_decoy='{"session_id":"'"$sid"'","tool_name":"Skill","tool_input":{"skill":"proxy:context","args":"\"skill\":\"proxy:solo\""}}'
skill_nosid='{"tool_name":"Skill","tool_input":{"skill":"proxy:solo"}}'
skill_badsid='{"session_id":"../../etc/passwd","tool_name":"Skill","tool_input":{"skill":"proxy:solo"}}'

run "$arm_cmd" "$skill_solo";        assert_eq "arm: proxy:solo -> marker created, silent" "present//0" "$(state)/$out/$rc"
run "$arm_cmd" "$skill_other";       assert_eq "arm: proxy:qa-plan -> marker untouched" "present//0" "$(state)/$out/$rc"
run "$arm_cmd" "$skill_pair";        assert_eq "arm: proxy:pair -> marker removed (decoy in args ignored)" "removed//0" "$(state)/$out/$rc"
run "$arm_cmd" "$skill_other_decoy"; assert_eq "arm: other skill with solo decoy in args -> still removed" "removed//0" "$(state)/$out/$rc"
run "$arm_cmd" "$skill_nosid";       assert_eq "arm: session_id absent -> silent, nothing created" "removed//0" "$(state)/$out/$rc"
run "$arm_cmd" "$skill_badsid";      assert_eq "arm: session_id with path chars -> nothing created" "removed/absent//0" "$(state)/$([ -e /tmp/claude-proxy-solo-etcpasswd ] && echo present || echo absent)/$out/$rc"
run "$arm_cmd" "";                   assert_eq "arm: empty stdin -> silent" "removed//0" "$(state)/$out/$rc"

touch "$marker"
run "$approve_cmd" "$compact"; assert_eq "approve: compact json, marker present -> allow" "$allow/0" "$out/$rc"
run "$approve_cmd" "$pretty";  assert_eq "approve: pretty json, marker present -> allow" "$allow/0" "$out/$rc"

rm -f "$marker"
run "$approve_cmd" "$compact"; assert_eq "approve: no marker -> silent" "/0" "$out/$rc"
run "$approve_cmd" "$nosid";   assert_eq "approve: session_id absent -> silent" "/0" "$out/$rc"
run "$approve_cmd" "$badsid";  assert_eq "approve: session_id with path chars -> silent" "/0" "$out/$rc"
touch "$marker"
run "$approve_cmd" "$othersid"; assert_eq "approve: marker for another session -> silent" "/0" "$out/$rc"
rm -f "$marker"
run "$approve_cmd" "";         assert_eq "approve: empty stdin -> silent" "/0" "$out/$rc"

touch "$marker"
run "$clear_cmd" "$prompt_auto";        assert_eq "clear: auto mode -> removed, silent" "removed//0" "$(state)/$out/$rc"
touch "$marker"
run "$clear_cmd" "$prompt_plan";        assert_eq "clear: plan mode -> kept, silent" "present//0" "$(state)/$out/$rc"
run "$clear_cmd" "$prompt_plan_pretty"; assert_eq "clear: pretty json, plan mode -> kept" "present//0" "$(state)/$out/$rc"
run "$clear_cmd" "$prompt_nomode";      assert_eq "clear: permission_mode absent -> removed (fail safe)" "removed//0" "$(state)/$out/$rc"
touch "$marker"
run "$clear_cmd" "";                    assert_eq "clear: empty stdin -> kept, silent" "present//0" "$(state)/$out/$rc"
run "$clear_cmd" "$nosid";              assert_eq "clear: session_id absent -> silent" "/0" "$out/$rc"

assert_eq "hooks.json: PreToolUse matcher is Skill" "Skill" "$arm_matcher"
assert_eq "hooks.json: PermissionRequest matcher is ExitPlanMode" "ExitPlanMode" "$approve_matcher"

exit $fail
