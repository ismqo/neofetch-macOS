#!/usr/bin/env bash
# Regression tests for neofetch.
#
# Every case runs neofetch in a clean environment ('env -i') whose PATH holds
# only the fake system tools in tests/fakes and a fixed set of basic utilities,
# so the output is the same on every Mac. Each case's stdout and stderr are
# compared with tests/golden/<case>.out.
#
#   tests/run.sh             run every case
#   tests/run.sh disk        run the cases whose name contains 'disk'
#   UPDATE=1 tests/run.sh    rewrite the golden files from the current output

set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
tests="$root/tests"
fakes="$tests/fakes"
golden="$tests/golden"
filter="${1:-}"

sandbox="$(mktemp -d "${TMPDIR:-/tmp}/neofetch-tests.XXXXXX")" || exit 1
trap 'rm -rf "$sandbox"' EXIT
# neofetch resolves config paths, so use the physical path ('/private/var/...').
sandbox="$(cd "$sandbox" && pwd -P)"

# Basic utilities neofetch may call; anything else is unavailable on purpose.
mkdir -p "$sandbox/utils"
for tool in awk bash basename cat chmod cmp cp cut dirname env find grep head id ls \
            make mkdir mkfifo mktemp mv readlink rm sed sleep sort stat tail tr \
            tty uniq wc; do
    path="$(PATH=/usr/bin:/bin command -v "$tool")" &&
        ln -s "$path" "$sandbox/utils/$tool"
done

pass=0
fail=0
updated=0
failed=()

reset_home() {
    # A fresh home, config directory and Homebrew prefix for each case.
    rm -rf "$sandbox/home" "$sandbox/xdg" "$sandbox/tmp" "$sandbox/brew" "$sandbox/INJECTED"
    mkdir -p "$sandbox/home" "$sandbox/xdg" "$sandbox/tmp" \
             "$sandbox/brew/Cellar/git" "$sandbox/brew/Cellar/jq" \
             "$sandbox/brew/Cellar/wget" "$sandbox/brew/Caskroom/firefox"
}

neofetch() {
    # Run neofetch in the sandbox. Leading NAME=value words set extra
    # environment variables (FAKE_ARCH, FAKE_DISK, FAKE_GPU, ...).
    local -a extra=()
    while [[ $# -gt 0 && "$1" == *=* && "$1" != -* ]]; do
        extra+=("$1")
        shift
    done

    # With neofetch_exec set (in a background subshell), replace that
    # subshell so its PID is neofetch's own.
    ${neofetch_exec:+exec} env -i \
        HOME="$sandbox/home" USER=tester HOSTNAME=testhost \
        SHELL="$fakes/zsh" TERM=xterm-256color TERM_PROGRAM=ghostty \
        GHOSTTY_BIN_DIR="$fakes" LANG=en_US.UTF-8 \
        PATH="$fakes:$sandbox/utils" XDG_CONFIG_HOME="$sandbox/xdg" \
        TMPDIR="$sandbox/tmp" FAKE_ROOT="$sandbox" \
        ${extra[@]+"${extra[@]}"} \
        bash "$root/neofetch" "$@"
}

check() {
    # check NAME: compare stdin byte for byte with tests/golden/NAME.out.
    # The '.' sentinel keeps trailing newlines, which $(...) would strip.
    local name=$1 actual expected
    actual="$(cat; printf .)"
    actual="${actual%.}"

    if [[ "${UPDATE:-}" ]]; then
        printf '%s' "$actual" > "$golden/$name.out"
        ((updated++))
        printf 'updated  %s\n' "$name"
        return
    fi

    if [[ -f "$golden/$name.out" ]]; then
        expected="$(cat "$golden/$name.out"; printf .)"
        expected="${expected%.}"
    fi

    if [[ -f "$golden/$name.out" && "$actual" == "$expected" ]]; then
        ((pass++))
        printf 'ok       %s\n' "$name"
    else
        ((fail++))
        failed+=("$name")
        printf 'FAIL     %s\n' "$name"
        if [[ -f "$golden/$name.out" ]]; then
            diff <(cat "$golden/$name.out") <(printf '%s' "$actual") | head -20 | sed 's/^/         /'
        else
            printf '         missing %s\n' "$golden/$name.out"
        fi
    fi
}

run_case() {
    # run_case NAME [NAME=value...] [neofetch args...]
    local name=$1
    shift
    [[ -z "$filter" || "$name" == *"$filter"* ]] || return 0

    reset_home
    check "$name" < <({ neofetch "$@" 2>&1; printf "exit=%s\n" "$?"; 
        [[ -e "$sandbox/INJECTED" ]] && echo "--- a command injected through the output ran"; } |
        sed -e "s|$sandbox|<sandbox>|g" -e "s|$root|<repo>|g")
}

config_case() {
    # config_case NAME CONFIG [neofetch args...]: run with tests/configs/CONFIG.
    local name=$1 config=$2
    shift 2
    [[ -z "$filter" || "$name" == *"$filter"* ]] || return 0

    reset_home
    cp "$tests/configs/$config" "$sandbox/home/config.conf"
    check "$name" < <({ neofetch --config "$sandbox/home/config.conf" "$@" 2>&1; printf "exit=%s\n" "$?"; 
        [[ -e "$sandbox/INJECTED" ]] && echo "--- a command injected through the output ran"; } |
        sed -e "s|$sandbox|<sandbox>|g" -e "s|$root|<repo>|g")
}

customize_case() {
    # customize_case NAME KEYS [CONFIG]: drive --customize with KEYS (printf
    # escapes allowed) and compare its last message, exit status and the
    # resulting config file.
    local name=$1 keys=$2 config=${3:-}
    [[ -z "$filter" || "$name" == *"$filter"* ]] || return 0

    reset_home
    local conf="$sandbox/home/config.conf"
    if [[ "$config" ]]; then
        cp "$tests/configs/$config" "$conf"
    else
        neofetch --print_config > "$conf"
    fi
    cp "$conf" "$sandbox/home/original"

    check "$name" < <({
        printf "$keys" | neofetch --config "$conf" --customize 2>&1 >/dev/null
        printf 'exit=%s\n' "$?"
        printf '%s\n' "--- config"
        cat "$conf"
        if [[ -f "$conf.bak" ]]; then
            cmp -s "$conf.bak" "$sandbox/home/original" &&
                echo "--- backup matches the original" ||
                echo "--- backup DIFFERS from the original"
        else
            echo "--- no backup"
        fi
        ls -A "$sandbox/tmp" | sed 's/^/--- leftover temp file: /'
    } | sed -e "s|$sandbox|<sandbox>|g" -e "s|$root|<repo>|g")
}

interrupt_case() {
    # interrupt_case NAME CONFIG: start a --customize save, send SIGTERM while
    # the new config is being checked, and report what was left behind.
    # (SIGINT can't be used: bash ignores it in background jobs.)
    local name=$1 config=$2 pid i
    [[ -z "$filter" || "$name" == *"$filter"* ]] || return 0

    reset_home
    rm -f "$sandbox/slow"
    local conf="$sandbox/home/config.conf"
    cp "$tests/configs/$config" "$conf"
    cp "$conf" "$sandbox/home/original"
    mkfifo "$sandbox/keys"

    neofetch_exec=1 neofetch --config "$conf" --customize < "$sandbox/keys" >/dev/null 2>&1 &
    pid=$!
    exec 7> "$sandbox/keys"
    sleep 0.5
    touch "$sandbox/slow"
    printf 's' >&7

    # Wait for the save's temporary file, then interrupt.
    for ((i = 0; i < 50; i++)); do
        ls "$sandbox/tmp" | grep -q . && break
        sleep 0.1
    done
    kill -TERM "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    exec 7>&-
    rm -f "$sandbox/keys" "$sandbox/slow"

    check "$name" < <({
        cmp -s "$conf" "$sandbox/home/original" &&
            echo "--- config unchanged" || echo "--- config CHANGED"
        ls -A "$sandbox/tmp" | sed 's/^/--- leftover temp file: /'
        true
    })
}

. "$tests/cases.sh"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
((fail == 0)) || { printf 'failed: %s\n' "${failed[*]}"; exit 1; }

# A run that checked or updated nothing (for example a mistyped filter)
# is not a pass.
if ((pass + updated == 0)); then
    printf 'no case matched %s\n' "${filter:-(no filter)}"
    exit 1
fi
