# A Functional Bash Style Guide

A synthesis of best practices for writing safe, predictable, maintainable Bash
code in a functional style. Distilled from:

- **Google Shell Style Guide** — function documentation, structure, formatting
- **progrium/bashstyle** — `main`-first design, named arguments via `declare`
- **bahamas10/bash-style-guide** — bashisms, `(( ))` arithmetic, anti-spaghetti
- **hthompson/bsg** (StrangeRanger) — error handling, modern idioms
- **LinuxCommand Coding Standards** — script structure, error handling functions
- **Wooledge's Bash Practices** — quoting, debugging, things never to do
- **Foo.zone Personal Style Guide** — assign-then-shift, pipes for data flow
- **dev.to "Bash Scripts Like A Pro"** — explicit functional decomposition

This guide is opinionated. Where the sources disagree, the choice that
*supports a functional, validated, testable style* wins.

---

## 1. Core Philosophy

LUCKy code lives in two contexts. This guide tags sections that apply to
only one; untagged sections apply to both.

- **Executables** — files in `bin/` and `lucky.sh`. Invoked with a shebang;
  may `exit`, may `set` shell options, own their environment.
- **Modules** — files in `mods-available/`. Sourced into the user's shell by
  `.bashrc`. Must not `exit` (kills the user's shell), must not
  `set -e/-u/-o pipefail` (leaks into the user's session), must not `trap`
  long-lived. Use `return` to stop early and `logmsg <ns>::<level>` for
  diagnostics. See STYLE.md for LUCKy-specific module conventions.

The three rules everything else follows from:

1. **Functions are the unit of code.** Top-level statements in an executable
   exist only to set shebang, options, constants, and to call `main`.
   Top-level statements in a module are limited to load-time setup, capability
   gates, and function definitions.
2. **Every function validates its arguments and defines what it returns.**
   No silent failures. No coupling to globals when an argument would do.
3. **Streams have jobs.** `stdout` is data. `stderr` is diagnostics. The exit
   code is the result. Don't mix them.

If a script grows past ~200 lines, or starts wanting maps, nested data
structures, or floating-point math, that is the signal to rewrite it in
Python, Go, or similar. Bash is glue.

---

## 2. Script Skeleton

**Applies to:** executables.

Every executable follows this layout:

```bash
#!/usr/bin/env bash
#
# script_name - One-line description.
#
# Usage: script_name [OPTIONS] ARGUMENTS
# Description: A longer explanation if needed.

set -o nounset    # Error on unset variables (-u)
set -o pipefail   # Pipeline fails if any stage fails
# Note: 'set -e' is intentionally omitted. See §7.

# ---------- Constants ----------
readonly PROGNAME="${0##*/}"
readonly VERSION='1.0.0'

# ---------- Functions ----------
log()       { printf '[%s] %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >&2; }
err()       { log "ERROR: $*"; }
die()       { err "$*"; exit 1; }

# ... other functions ...

main() {
    # Parse arguments, call other functions.
    # main is the only function allowed to be "impure".
    :
}

# Allow file to be sourced as a library without running main.
[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
```

**Shebang.** Use `#!/usr/bin/env bash`. `/bin/bash` is not portable (BSDs,
macOS Homebrew, etc.). Pinning to `/bin/bash` is only acceptable when
intentionally targeting a known environment.

**File extensions.** Executables: no extension. Libraries meant to be
sourced: `.sh` or `.bash`. Never put `.sh` on a script users run.

**Sourcing as library.** The `[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"`
pattern lets a script be either run directly or sourced for its functions.
Tests love this.

---

## 3. Functions: The Heart of the Style

### 3.1 Mandatory function header

Every function that is not trivially obvious gets a header. Every function
in a library gets a header. The header documents the **API contract** — if
you can use the function from the comments alone, the comment is doing its
job.

```bash
#######################################
# Move a file into the backup directory, renaming it with a timestamp.
# Globals:
#   BACKUP_DIR (read)
# Arguments:
#   $1 - source_path: absolute path to file to back up
# Outputs:
#   STDOUT: the new path of the backed-up file
#   STDERR: error messages on failure
# Returns:
#   0 on success
#   1 if source_path is missing or unreadable
#   2 if BACKUP_DIR does not exist
#######################################
backup_file() {
    # ...
}
```

The five fields — **Description, Globals, Arguments, Outputs, Returns** —
are non-negotiable. If a function reads no globals, write "Globals: none."
Don't omit the section. The explicitness *is* the value.

### 3.2 Named arguments (assign-then-shift)

Never use `$1`, `$2`, etc. in function bodies. Bind them to local names
immediately.

```bash
backup_file() {
    local source_path="$1"; shift
    # ...
}
```

Adding, removing, or reordering parameters requires no other edits inside
the function — every `local x="$1"; shift` line is identical.

### 3.3 Argument validation — every function, every time

A function that doesn't validate its arguments is a bug waiting to happen.
Bash will silently produce garbage when called wrong.

Three tools, in order of preference:

**(a) Parameter expansion `:?` for required args (best):**

```bash
backup_file() {
    local source_path="${1:?source_path required}"; shift
    [[ -r "$source_path" ]] || { err "not readable: $source_path"; return 1; }
    # ...
}
```

The `${1:?msg}` form aborts with `msg` on stderr if `$1` is unset or empty.
Use this for arguments that have no sensible default.

**(b) `:-` for optional args with defaults:**

```bash
greet() {
    local name="${1:-stranger}"; shift
    local greeting="${1:-Hello}"; shift
    printf '%s, %s!\n' "$greeting" "$name"
}
```

**(c) Explicit count check when variadic:**

```bash
sum_at_least_two() {
    (( $# >= 2 )) || { err "need at least 2 args, got $#"; return 1; }
    # ...
}
```

**Always also validate the shape of the input** when the type matters:

```bash
parse_port() {
    local port="${1:?port required}"
    [[ "$port" =~ ^[0-9]+$ ]] || { err "port not numeric: $port"; return 1; }
    (( port > 0 && port < 65536 ))   || { err "port out of range: $port"; return 1; }
    printf '%s\n' "$port"
}
```

### 3.4 Purity, or as close as bash gets

Aim for **pure functions**: output depends only on arguments, no global
reads, no global writes, output goes to stdout, diagnostics to stderr,
result encoded in exit status. Bash will not let you be religious about
this, but the closer you get, the more testable your code becomes.

```bash
# Pure: same input → same output, no side effects.
sanitize_name() {
    local raw="${1:?raw name required}"; shift
    local sanitized="${raw,,}"        # lowercase
    sanitized="${sanitized// /_}"     # spaces to underscores
    sanitized="${sanitized//[^a-z0-9_]/}"
    printf '%s\n' "$sanitized"
}
```

When a function *must* touch global state, say so in the header's
`Globals:` field. Functions that touch globals should be a small,
identifiable set.

### 3.5 Return values vs. output

| You want to return... | Use                  |
|-----------------------|----------------------|
| A status (ok/fail)    | exit code via `return N` |
| A string / data       | `printf` to stdout, capture with `$(fn ...)` |
| Multiple values       | newline-delimited stdout, read with `mapfile` / `read` |
| A diagnostic          | `printf ... >&2`     |

Never mix. Functions that return data should write *only* data to stdout.

```bash
get_hostname() {
    local fqdn="${1:?fqdn required}"; shift
    local host
    IFS=. read -r host _ <<< "$fqdn"
    printf '%s\n' "$host"
}
```

### 3.6 No nested function definitions

Don't define functions inside other functions. They're not lexically
scoped — they pollute the global namespace just like top-level functions,
but hidden where readers won't find them.

### 3.7 Function ordering

Define functions before they are called. Read top-to-bottom, leaves first,
`main` (executables) or load-time setup (modules) last.

For executables: no executable code between function definitions (see §8.8).
For modules: load-time setup may interleave with definitions, but the
"define before called" rule still applies.

---

## 4. Variables

### 4.1 Naming

| Kind                  | Convention                 | Example                |
|-----------------------|----------------------------|------------------------|
| Local to a function   | `snake_case`               | `local file_count`     |
| File-scope constant   | `UPPER_SNAKE` + `readonly` | `readonly MAX_RETRIES=3` |
| Exported (env)        | `UPPER_SNAKE` + `export`   | `export LOG_LEVEL=info`|
| Function names        | `kebab-case`               | `process-file()`       |

- No `camelCase`.
- Uppercase is reserved for constants and exports.
- LUCKy-owned exports use the `LUCKY_` prefix (`LUCKY_DIR`, `LUCKY_PREFIX`, …) — see STYLE.md.

### 4.2 Declaration

- Inside functions: always `local`.
- File-scope constants: `readonly` (executables only — modules export `LUCKY_*` instead).
- Arrays: `local -a` for indexed, `local -A` for associative.

`local` and command substitution don't mix safely — `local x="$(cmd)"` discards `cmd`'s exit code. Split it:

```bash
local result
result="$(some_command)" || return 1
```

### 4.3 Quoting

**When in doubt, quote.** Quote every variable expansion and command
substitution unless you have a specific, documented reason not to.

```bash
# Always:
cp "$src" "$dst"
echo "$user logged in at $(date)"

# Single quotes for true literals (no expansion needed):
readonly PROMPT='enter $USER:'

# Inside [[ ... ]], quoting is optional for the LHS but recommended for clarity.
# Note: the RHS of =~ must NOT be quoted, or the pattern becomes a literal string.
[[ "$file" =~ \.txt$ ]]
```

Foo.zone argues against quoting "obviously safe" variables. This guide
sides with Google: **quote everything**. The consistency wins; the
once-in-a-blue-moon time it bites you is too painful.

### 4.4 Braces

Use `${var}` when needed for disambiguation. Don't use it everywhere just
to look fancy — it's not a form of quoting and adds visual noise.

```bash
# Necessary: would be parsed as $USERs otherwise.
echo "${USER}s home"

# Unnecessary noise:
echo "${name} is ${age}"
# Same as:
echo "$name is $age"
```

Inside `$(( ... ))`, omit the `$` entirely — the shell knows to look up
variables there.

```bash
local -i total
(( total = price * quantity ))
```

---

## 5. Bashisms (Prefer Builtins)

This is a bash script, not a portable sh script. Use bash features.

### 5.1 Conditionals: always `[[ ... ]]`

```bash
# CORRECT
[[ -d "$dir" ]] && cd "$dir"
[[ "$name" == "alice" ]]
[[ "$name" =~ ^[a-z]+$ ]]

# WRONG
[ -d "$dir" ]    # POSIX test, has word-splitting hazards
test -d "$dir"   # same
```

`[[ ... ]]` is shell syntax, not a command. It doesn't word-split, doesn't
glob-expand, and supports regex. There is no reason to use `[` in a bash
script.

### 5.2 Arithmetic: always `(( ... ))` or `$(( ... ))`

```bash
# CORRECT
(( count++ ))
(( total = a + b ))
if (( count > 10 )); then ...
local result=$(( a * b ))

# WRONG
let count++              # quoting hazards, can execute commands
count=$((count+1)); export count=$[count+1]   # $[..] is deprecated
i=`expr $i + 1`          # fork to external program, slow, fragile
```

Pitfall: a `(( expr ))` whose result is zero returns exit code 1. Under
`set -e` this exits the script — another reason to avoid `set -e` (§7).

### 5.3 Command substitution: always `$( ... )`

```bash
# CORRECT
date="$(date +%Y-%m-%d)"
nested="$(echo "$(date)" | tr ' ' '_')"

# WRONG
date=`date +%Y-%m-%d`     # nesting requires backslash escapes
```

### 5.4 Parameter expansion over external tools

For string manipulation that bash can do natively, do it natively.

```bash
filename='report.2026-05-19.txt'

# CORRECT
basename="${filename##*/}"      # strip path
stem="${filename%.*}"           # strip extension
date_part="${filename%.txt}"
date_part="${date_part#report.}"
uppercase="${filename^^}"       # bash 4+

# WRONG
basename=$(basename "$filename")
stem=$(echo "$filename" | sed 's/\.[^.]*$//')
```

This is faster and more reliable. Reserve `sed` / `awk` / `cut` for
genuinely complex text processing — multi-line regexes, field-based
manipulation of structured input, etc. Don't fork a process to delete a
suffix.

### 5.5 Sequences and loops

```bash
# CORRECT
for i in {1..10}; do ... done            # fixed range
for ((i = 0; i < n; i++)); do ... done   # variable range
for file in *.txt; do ... done           # glob, NOT `for f in $(ls *.txt)`

# WRONG
for i in $(seq 1 10); do ... done        # forks seq, splits on whitespace
for line in $(< file); do ... done       # splits on $IFS, not lines
for f in $(ls); do ... done              # PARSING LS, DRAGONS
```

### 5.6 Reading lines from files

```bash
# CORRECT — streams, handles whitespace and special characters
while IFS= read -r line; do
    process "$line"
done < "$file"

# Or with field splitting:
while IFS=: read -r user _ uid _; do
    printf '%s -> %d\n' "$user" "$uid"
done < /etc/passwd

# Or read whole file into an array:
mapfile -t lines < "$file"
```

Never pipe to `while`. A pipe creates a subshell, so variable changes
inside the loop are lost:

```bash
# WRONG — count stays 0 outside the loop
count=0
cat file | while read -r line; do
    (( count++ ))
done
echo "$count"   # prints 0
```

Use process substitution `< <( ... )` instead:

```bash
count=0
while IFS= read -r line; do
    (( count++ ))
done < <(generate_lines)
echo "$count"   # correct
```

### 5.7 Arrays

Use arrays for lists. Never use space-separated strings.

```bash
# CORRECT
local -a flags=(--verbose --output=/tmp/out --retries=3)
my_binary "${flags[@]}"

# WRONG
local flags='--verbose --output=/tmp/out --retries=3'
my_binary $flags    # word-splits, breaks on spaces in values
```

`"${array[@]}"` expands each element as its own quoted argument — that's
what you almost always want. `"${array[*]}"` joins them into one string
with `$IFS`.

If your data needs more structure than "list of strings" or "key → string",
**stop and use a different language.** Bash arrays cannot nest.

---

## 6. Output and Stream Discipline

Three streams, three jobs:

| Stream | Purpose                                  |
|--------|------------------------------------------|
| stdout | The function's data output.              |
| stderr | Logs, progress, diagnostics, errors.     |
| exit   | The function's status (0 = success).     |

A function that produces data writes that data — and *only* that data —
to stdout. A function whose only purpose is a side effect writes nothing
to stdout. Diagnostics always go to stderr, including informational logs:
that way the caller can pipe the function's output without contamination.

**Prefer `printf` over `echo`.** `echo` interprets `-e`, `-n`, and
escape sequences inconsistently across platforms. `printf` is predictable:

```bash
printf '%s\n' "$value"        # one value, newline
printf '%s\n' "${arr[@]}"     # one per line
printf '%-20s %s\n' "$key" "$val"   # formatted
```

### 6.1 Diagnostic helpers

**Executables** define `log`/`err`/`die`:

```bash
log()  { printf '[%s] %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >&2; }
warn() { log "WARNING: $*"; }
err()  { log "ERROR: $*"; }
die()  { err "$*"; exit 1; }
```

**Modules** use `logmsg <ns>::<level> <message>` from `00_lucky_core.sh`.
Don't define `die` in a module — `exit` would kill the user's shell.

---

## 7. Error Handling

Approaches differ by context. The core idea is the same in both:
explicit checks, no silent failures, diagnostics on stderr, status in
the exit code.

### 7.1 Shell options

**Applies to:** executables.

```bash
set -o nounset   # -u: treat unset variables as errors
set -o pipefail  # exit code of a pipeline is non-zero if any stage failed
# Deliberately NOT: set -o errexit (-e). See §7.5.
```

Modules must not set these — `set` mutations leak into the user's
interactive shell and break unrelated commands.

### 7.2 Modules: log + return

**Applies to:** modules.

Modules signal failure by logging via `logmsg <ns>::error <msg>` and
returning a non-zero status. Never `exit`.

```bash
function fetch-config() {
    local url="${1:?url required}"
    local out
    out=$(curl -fsSL "$url") || {
        logmsg fetch::error "could not fetch $url"
        return 1
    }
    printf '%s\n' "$out"
}
```

### 7.3 Executables: explicit checks with `die`

**Applies to:** executables.

```bash
cd "$work_dir"          || die "cannot cd to $work_dir"
mkdir -p "$out_dir"     || die "cannot create $out_dir"
process "$file"         || die "process failed on $file"
```

### 7.4 Pipelines

With `set -o pipefail`, `$?` reflects the pipeline as a whole. For
per-stage checks use `PIPESTATUS`:

```bash
sort < "$input" | uniq > "$output"
local -a statuses=( "${PIPESTATUS[@]}" )
(( statuses[0] == 0 )) || die "sort failed"      # executable
(( statuses[1] == 0 )) || die "uniq failed"
```

Module variant: replace `die` with
`logmsg <ns>::error "..."; return 1`.

### 7.5 Why this guide is skeptical of `set -e`

`set -e` has surprising exemptions: commands in `if`, `&&`, `||`,
pipelines (except the last), `!`, and subshells in various combinations
are immune. The rules have changed between bash versions. A `(( i++ ))`
where `i` becomes zero exits the script.

Explicit `|| die "..."` (or `|| { logmsg <ns>::error ...; return 1; }`
in modules) is safer because it composes with the function-validation
rules.

### 7.6 Cleanup with `trap`

**Applies to:** executables.

```bash
cleanup() {
    local exit_code=$?
    [[ -n "${WORK_DIR:-}" ]] && rm -rf "$WORK_DIR"
    exit "$exit_code"
}
trap cleanup EXIT INT TERM HUP

WORK_DIR="$(mktemp -d)" || die "mktemp failed"
```

`trap` in a sourced module would persist for the user's session — don't.
A module that allocates a resource releases it inline, or stores it
under `$LUCKY_RUNDIR` for cross-shell reuse (see `40_ssh_agent.sh`).

### 7.7 `mktemp`, always

Never hardcode `/tmp/myscript.tmp`. Race conditions, symlink attacks,
collisions with other instances.

```bash
# Executable:
local tmpfile
tmpfile="$(mktemp)" || die "mktemp failed"

# Module:
local tmpfile
tmpfile="$(mktemp)" || { logmsg mymod::error "mktemp failed"; return 1; }
```

For temp directories: `mktemp -d`.

---

## 8. Things To Never Do

A short list of the most dangerous patterns. These cause real outages.

1. **Don't parse `ls`.** Filenames can contain spaces, newlines, control
   chars, and leading dashes. Use globs (`for f in *`) or `find -print0`.
2. **Don't use `for line in $(cat file)`.** Use `while IFS= read -r line`.
3. **Don't use `eval`.** Almost always replaceable with arrays or
   parameter indirection. If you think you need it, you don't.
4. **Don't use unquoted globs as command arguments without `./` prefix.**
   A file named `-rf` in your directory will ruin your day.
5. **Don't use backticks.** Use `$( ... )`.
6. **Don't fork to `expr`, `seq`, `basename`, `dirname`, or `echo | sed`
   when bash has a builtin.** They are slow and unnecessary.
7. **Don't write `[ "$x" = "$y" ]` in a bash script.** Use `[[ ]]`.
8. **(Executables only) Don't put executable code between function
   definitions.** Header, constants, functions, `main "$@"`, end of file.
   Modules legitimately interleave load-time setup with definitions.
9. **Don't use SUID/SGID on shell scripts.** It's not securable.

---

## 9. Formatting

- **Indentation:** 4 spaces. Hard rule: no mixing tabs and spaces. (Google
  says 2; the source guides disagree; this guide picks 4 for readability
  parity with most other languages. Be consistent within a project.)
- **Line length:** 80 characters. Long lines should be broken with
  continuation `\` or by extracting to variables and helper functions.
- **`then` / `do`:** same line as `if` / `for` / `while`, separated by
  `;`. `else`, `fi`, `done` on their own lines, vertically aligned.
- **Blank lines:** one between logical blocks; never more than one in a
  row. One blank line between function definitions.
- **No semicolons** at end of regular lines; reserve them for `then`/`do`.
- **No aliases in scripts.** Use functions.

```bash
process_files() {
    local -a files=("$@")
    local file

    for file in "${files[@]}"; do
        if [[ -r "$file" ]]; then
            handle_file "$file"
        else
            warn "skipping unreadable: $file"
        fi
    done
}
```

Long commands: prefer one option per line for readability.

```bash
rsync \
    --archive \
    --delete-excluded \
    --exclude-from="$EXCLUDE_FILE" \
    "$source" "$dest" \
    || die "rsync failed"
```

Long pipelines: pipe at the start of the continuation line — the `|` is
the eye-catcher that tells you it's a pipeline rather than a continued
command.

```bash
find . -type f -name '*.log' \
    | sort \
    | uniq -c \
    | sort -rn \
    | head -20
```

---

## 10. Composition: Pipes as Data Flow

**Applies to:** executables.

A bash idiom that fits the functional style: write small stage functions
that read from stdin and write to stdout, and compose them with pipes in
`main`. Each stage is a pure transformation of a stream.

```bash
extract_errors() {
    grep -E '^(ERROR|FATAL)'
}

normalize_timestamps() {
    sed -E 's/^[0-9-]+T[0-9:.+]+ //'
}

count_by_message() {
    sort | uniq -c | sort -rn
}

main() {
    local logfile="${1:?logfile required}"

    extract_errors          \
        < "$logfile"        \
        | normalize_timestamps \
        | count_by_message
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
```

Each stage is independently testable: `echo $'ERROR foo\nINFO bar' |
extract_errors` should print one line. The script reads like a data
pipeline because it is one.

---

## 11. User-facing library functions

A library function exposed to the user — anything sourced into the
interactive shell that the user might type by name (`youtuber`,
`rand-password`, `mkgif`, …) — should print a short usage to stderr when
called with no arguments or invalid ones, and return non-zero.

Pattern is a `case` switch that handles the help/bad-input path and lets
valid invocations fall through. `rand-password` in `70_passwd_gen.sh` is
the model:

```bash
function rand-password() {
    case "$1" in
        96bit)   head -c 12 /dev/urandom | base64 ;;
        120bit)  head -c 15 /dev/urandom | base64 ;;
        *)
            cat >&2 <<-EOF
            syntax: rand-password [type]
              avail generators:
                96bit:   base64-encoded (~16 chars)
                120bit:  base64-encoded (~20 chars)
            EOF
            return 1
            ;;
    esac
}
```

- Usage text goes to stderr so the function still composes in pipes.
- Return non-zero on the help/bad-input path so callers can detect misuse.
- Don't `exit` — this runs in the user's shell.

For full option parsing in executables (`lucky.sh`, `bin/*`), see the
`case`-style argument loop in §14.

---

## 12. Testing

The whole point of all this discipline is that you can test it. A
function that:

- Takes its inputs as arguments
- Validates them
- Writes data to stdout
- Returns a meaningful exit code

…is testable from any test harness. `bats` is the most common one, but
plain bash works too:

```bash
# In test_backup.sh
source ./backup.sh   # because we used the BASH_SOURCE guard, no main runs

test_sanitize_strips_spaces() {
    local got
    got="$(sanitize_name 'Hello World')"
    [[ "$got" == 'hello_world' ]] || { echo "FAIL: got '$got'"; return 1; }
}

test_sanitize_strips_spaces && echo PASS
```

Modules are harder to test wholesale because sourcing one performs
load-time setup against the running shell. The exported functions
themselves are unit-testable in isolation: source the module in a
disposable subshell, then call the function with constructed inputs.

---

## 13. Tooling

- **`shellcheck`.** Non-negotiable. Run it on every script, in CI, every
  time. It catches roughly half of the mistakes this guide warns about,
  including ones you wouldn't think to look for. Add `# shellcheck
  disable=SCXXXX` only with a comment explaining why.
- **`shfmt`.** Auto-formats bash to a consistent style. Reduces bikeshedding.
- **`bats-core`.** Testing framework if you have more than a handful of
  functions to test.
- **`TRACE=1 ./script.sh`.** A nice idiom: include
  `[[ "${TRACE:-0}" == "1" ]] && set -x` near the top of an executable,
  and you have on-demand tracing. (Don't do this in a module — `set -x`
  would persist in the user's shell.)

---

## 14. A Worked Example

**Applies to:** executables.

A complete script that follows every rule in this guide.

```bash
#!/usr/bin/env bash
#
# tally - count occurrences of each line in one or more files.
#
# Usage: tally [-h] [-n N] FILE...
# Outputs: lines of "<count><tab><value>", most frequent first.

set -o nounset
set -o pipefail
[[ "${TRACE:-0}" == "1" ]] && set -x

readonly PROGNAME="${0##*/}"
readonly VERSION='1.0.0'

# ---------- diagnostics ----------
log()  { printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*" >&2; }
err()  { log "ERROR: $*"; }
die()  { err "$*"; exit 1; }

# ---------- usage ----------
#######################################
# Print usage text.
# Globals: PROGNAME, VERSION (read)
# Arguments: none
# Outputs: STDOUT: help text
# Returns: 0
#######################################
usage() {
    cat <<EOF
$PROGNAME $VERSION

Count occurrences of each line across one or more files.

Usage: $PROGNAME [-h] [-n N] FILE...

Options:
    -h          Show this help.
    -n N        Show only the top N most frequent (default: all).
EOF
}

# ---------- pure stages ----------
#######################################
# Validate that all paths are readable regular files.
# Globals: none
# Arguments: $@ - one or more file paths
# Outputs: STDERR on failure
# Returns: 0 if all readable, 1 otherwise.
#######################################
validate_files() {
    (( $# > 0 )) || { err "no files given"; return 1; }
    local file
    for file in "$@"; do
        [[ -f "$file" ]] || { err "not a regular file: $file"; return 1; }
        [[ -r "$file" ]] || { err "not readable: $file"; return 1; }
    done
    return 0
}

#######################################
# Stream all lines from given files to stdout.
# Globals: none
# Arguments: $@ - file paths (already validated)
# Outputs: STDOUT: one line per input line
# Returns: 0
#######################################
emit_lines() {
    (( $# > 0 )) || { err "emit_lines: no files"; return 1; }
    cat -- "$@"
}

#######################################
# Count and sort lines from stdin, most frequent first.
# Globals: none
# Arguments: none
# Outputs: STDOUT: "<count>\t<line>" rows
# Returns: 0
#######################################
tally_lines() {
    sort | uniq -c | sort -rn | sed -E 's/^ *([0-9]+) +/\1\t/'
}

#######################################
# Limit stdin to first N lines.
# Globals: none
# Arguments: $1 - N (positive integer), or empty for no limit
# Outputs: STDOUT: first N lines (or all)
# Returns: 0 on success, 1 on bad N
#######################################
limit() {
    local n="${1:-}"; shift || true
    if [[ -z "$n" ]]; then
        cat
        return 0
    fi
    [[ "$n" =~ ^[0-9]+$ ]] || { err "limit: bad N: $n"; return 1; }
    (( n > 0 )) || { err "limit: N must be positive"; return 1; }
    head -n "$n"
}

# ---------- main ----------
main() {
    local top=''
    local -a files=()

    while (( $# > 0 )); do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -n)        top="${2:?-n requires a value}"; shift 2 ;;
            --)        shift; files+=("$@"); break ;;
            -*)        usage >&2; die "unknown option: $1" ;;
            *)         files+=("$1"); shift ;;
        esac
    done

    validate_files "${files[@]}" || exit 1

    emit_lines "${files[@]}" \
        | tally_lines        \
        | limit "$top"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
```

That's the whole style guide, applied. Each stage function is a pure
transformation. Each takes its inputs as arguments (or stdin), validates
them, writes data to stdout, diagnostics to stderr, and returns a
meaningful exit code. `main` is the only impure function — it parses
options and wires up the pipeline. The script can be sourced as a
library and every function tested in isolation.

---

## Appendix A: Quick Reference Card

| Do                              | Don't                          |
|---------------------------------|--------------------------------|
| `#!/usr/bin/env bash`           | `#!/bin/bash` (non-portable)   |
| `[[ ... ]]`                     | `[ ... ]`, `test ...`          |
| `(( ... ))` and `$(( ... ))`    | `let`, `expr`, `$[ ... ]`      |
| `$( ... )`                      | `` ` ... ` ``                  |
| `local x="$1"; shift`           | use `$1` directly through body |
| `${1:?msg}` / `${1:-default}`   | naked `$1` with no validation  |
| `printf '%s\n' "$x"`            | `echo "$x"` (flag inconsistency) |
| `mapfile -t arr < file`         | `arr=( $(cat file) )`          |
| `while read -r line; do ... done < file` | `for line in $(cat file)` |
| `for f in *.txt`                | `for f in $(ls *.txt)`         |
| `mkdir -p "$d" \|\| die "..."`   | `mkdir -p $d`                  |
| `trap cleanup EXIT` (exec)      | rely on user pressing Ctrl-C   |
| `mktemp`                        | `/tmp/myscript.$$`             |
| stdout = data, stderr = logs    | mix them                       |

## Appendix B: Sources

- Google Shell Style Guide — https://google.github.io/styleguide/shellguide.html
- progrium/bashstyle — https://github.com/progrium/bashstyle
- bahamas10/bash-style-guide — https://github.com/bahamas10/bash-style-guide
- hthompson/bsg — https://bsg.hthompson.dev/
- LinuxCommand Coding Standards — https://linuxcommand.org/lc3_adv_standards.php
- Wooledge BashGuide/Practices — https://mywiki.wooledge.org/BashGuide/Practices
- Foo.zone Personal Bash Style — https://foo.zone/gemfeed/2021-05-16-personal-bash-coding-style-guide.html
- dev.to "Bash Scripts Like A Pro" — https://dev.to/unfor19/writing-bash-scripts-like-a-pro-part-1-styling-guide-4bin

## Appendix C: Required Tooling

```
shellcheck    # static analysis — required in CI
shfmt         # formatter (optional but recommended)
bats-core     # test framework (optional)
```
