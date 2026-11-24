#!/bin/bash
#
# Runs the demo's UI tests on this Mac, on the platforms and versions that are chosen.
#
# The tests are not run in CI, because a hosted runner is too small for a simulator,
# so this is how they are run before a pull request. With no rows named, a list of
# them is shown to choose from. A row whose version is not on this Mac can be chosen
# as well: the version is then downloaded first, which takes several gigabytes, after
# asking.
#
# usage: scripts/run-demo-tests.sh [options] [row...]
#
# A row is `all`, a platform (`ios`, `macos`, `watchos`, `visionos`, `tvos`), or a
# platform and a version (`ios-18.5`). Rows are run one after another. On a simulator
# the suites of a row run side by side on copies of it (the DemoParallel test plan);
# the tests of the Mac app run one at a time, and last, because they take over the
# pointer and the keyboard.
#
# Options:
#   --list            Show the rows and whether each can be run, and stop.
#   --download        Download the versions that are named and not on this Mac,
#                     without asking. Without it, `all` and a platform leave them out.
#   --workers N       How many copies of a simulator run the suites of a row. The
#                     default is 3, and 2 on a watch and on visionOS.
#   --serial          Run one test at a time on every row (the Demo test plan).
#   --only-testing T  Run only the test, or the suite, T, such as
#                     DemoUITests/FruitListTests. Can be given more than once.
#   --help            Show this text.
#
# The log and the result bundle of each row are kept in .build/demo-tests, in a
# folder named after the time of the run.

set -euo pipefail

cd "$(dirname "$0")/.."

# The versions the tests are meant to pass on: one from each major version of each
# platform that has simulators. A version with no minor part is the newest of that
# major version. A new version is added here.
wanted=(
    "iOS 18.5" "iOS 26.5" "iOS 27"
    "watchOS 11.5" "watchOS 26.5" "watchOS 27"
    "visionOS 2.5" "visionOS 26.5" "visionOS 27"
    "tvOS 18.5" "tvOS 26.5" "tvOS 27"
)

project="Examples/Demo/Demo.xcodeproj"
scheme="Demo"
root=".build/demo-tests"
derived_data="$root/derived-data"

# Options.

list_only=false
serial=false
download=false
workers=""
only_testing=()
selectors=()

usage() {
    sed -n '2,/^$/p' "$0" | sed -e 's/^# \{0,1\}//' -e '$d'
}

while [ $# -gt 0 ]; do
    case "$1" in
        --list) list_only=true ;;
        --serial) serial=true ;;
        --download) download=true ;;
        --workers)
            shift
            workers="${1:-}"
            case "$workers" in
                '' | *[!0-9]* | 0)
                    echo "--workers takes a number of 1 or more." >&2
                    exit 2
                    ;;
            esac
            ;;
        --only-testing)
            shift
            if [ -z "${1:-}" ]; then
                echo "--only-testing takes the name of a test or a suite." >&2
                exit 2
            fi
            only_testing+=("$1")
            ;;
        --help | -h)
            usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
        *) selectors+=("$1") ;;
    esac
    shift
done

# Colours, only where the output is a terminal.

if [ -t 1 ]; then
    bold=$'\033[1m' dim=$'\033[2m' red=$'\033[31m' green=$'\033[32m' yellow=$'\033[33m' plain=$'\033[0m'
else
    bold="" dim="" red="" green="" yellow="" plain=""
fi

# The rows. Each is a platform and a version, with the simulator to run it on, or the
# reason it cannot be run. They are kept in arrays with the same order.

row_platform=()
row_version=()
row_label=()
row_udid=()
row_note=()
row_state=()
row_wanted=()
row_group=()
row_chosen=()

add_row() {
    row_platform+=("$1")
    row_version+=("$2")
    row_label+=("$3")
    row_udid+=("$4")
    row_note+=("$5")
    row_state+=("$6")
    row_group+=("$7")
    row_chosen+=(false)
}

# Reads the simulators of this Mac: platform, version, name and identifier of each,
# the newest version first. visionOS is xrOS to the simulator. And its runtimes, with
# the identifier of each, to tell a version that is missing from one that has no
# simulator.
simulators=""
runtimes=""
read_simulators() {
    simulators=$(
        xcrun simctl list -j | jq -r '
            (.runtimes | map(select(.isAvailable)) | map({
                key: .identifier,
                value: {platform: (if .platform == "xrOS" then "visionOS" else .platform end), version}
            }) | from_entries) as $runtimes
            | .devices | to_entries[] | select($runtimes[.key]) | .key as $runtime
            | .value[] | select(.isAvailable)
            | [$runtimes[$runtime].platform, $runtimes[$runtime].version, .name, .udid] | @tsv
        ' | sort -t "$(printf '\t')" -k1,1 -k2,2Vr
    )
    runtimes=$(
        xcrun simctl list -j runtimes | jq -r '
            .runtimes[] | select(.isAvailable)
            | [(if .platform == "xrOS" then "visionOS" else .platform end), .version, .identifier] | @tsv
        ' | sort -t "$(printf '\t')" -k1,1 -k2,2Vr
    )
}
read_simulators

# Whether a version is the one wanted: the same, or of the major version wanted.
version_matches() {
    local version="$1" wanted_version="$2"
    case "$wanted_version" in
        *.*) [ "$version" = "$wanted_version" ] ;;
        *) [ "$version" = "$wanted_version" ] || [ "${version%%.*}" = "$wanted_version" ] ;;
    esac
}

# The newest version of a platform on this Mac that is the one wanted, or nothing.
installed_version() {
    local platform="$1" wanted_version="$2" found_platform version
    while IFS=$'\t' read -r found_platform version _; do
        if [ "$found_platform" = "$platform" ] && version_matches "$version" "$wanted_version"; then
            echo "$version"
            return
        fi
    done <<< "$3"
}

# The first of some lines, each a name, a tab and an identifier, that is the plain
# model of the usual device of a platform, or failing that any device of it.
pick_usual() {
    local platform="$1" candidates="$2" preferred pattern
    case "$platform" in
        iOS) preferred='^iPhone [0-9]+	|^iPhone [0-9]+ Pro	|^iPhone ' ;;
        watchOS) preferred='^Apple Watch Series [0-9]+ \(46mm\)	|^Apple Watch Series |^Apple Watch ' ;;
        tvOS) preferred='^Apple TV 4K \([^)]*\)	|^Apple TV' ;;
        *) preferred='^Apple Vision' ;;
    esac
    while IFS= read -r pattern; do
        if grep -E -m 1 "$pattern" <<< "$candidates"; then
            return
        fi
    done <<< "${preferred//|/$'\n'}"
}

# The simulator to use for a platform and a version, as `name<tab>identifier`.
pick_simulator() {
    local platform="$1" version="$2"
    pick_usual "$platform" "$(awk -F '\t' -v p="$platform" -v v="$version" '$1 == p && $2 == v { print $3 "\t" $4 }' <<< "$simulators")"
}

# Works out whether a row can be run now, and on which simulator. A row is `ready`,
# has `nosimulator` for a version that is here, or is `missing`.
resolve_row() {
    local index="$1" platform="${row_platform[$1]}" wanted_version="${row_wanted[$1]}" version simulator=""
    version=$(installed_version "$platform" "$wanted_version" "$simulators")
    if [ -n "$version" ]; then
        simulator=$(pick_simulator "$platform" "$version")
    fi
    if [ -n "$simulator" ]; then
        row_version[$index]="$version"
        row_label[$index]="$platform $version"
        row_udid[$index]="${simulator#*	}"
        row_note[$index]="${simulator%%	*}"
        row_state[$index]=ready
    elif [ -n "$(installed_version "$platform" "$wanted_version" "$runtimes")" ]; then
        row_note[$index]="no simulator for it: one is made first"
        row_state[$index]=nosimulator
    else
        row_note[$index]="not installed: it is downloaded first, which takes several gigabytes"
        row_state[$index]=missing
    fi
}

for entry in "${wanted[@]}"; do
    add_row "${entry%% *}" "${entry#* }" "$entry" "" "" missing wanted
    row_wanted+=("${entry#* }")
    resolve_row $((${#row_label[@]} - 1))
done

add_row macOS "" "macOS" "" "this Mac: takes over the pointer and the keyboard" ready wanted
row_wanted+=("")

# Every other version that has a simulator here.
while IFS=$'\t' read -r platform version; do
    [ -n "$platform" ] || continue
    known=false
    for index in "${!row_label[@]}"; do
        if [ "${row_platform[$index]}" = "$platform" ] && [ "${row_version[$index]}" = "$version" ]; then
            known=true
        fi
    done
    if ! $known; then
        simulator=$(pick_simulator "$platform" "$version")
        if [ -n "$simulator" ]; then
            add_row "$platform" "$version" "$platform $version" "${simulator#*	}" "${simulator%%	*}" ready extra
            row_wanted+=("$version")
        fi
    fi
done <<< "$(cut -f 1,2 <<< "$simulators" | uniq)"

row_count=${#row_label[@]}

# The list of rows, as it is shown by --list and in the chooser.

row_line() {
    local index="$1" mark="$2"
    if [ "${row_state[$index]}" = ready ]; then
        printf '%s %-14s %s%s%s' "$mark" "${row_label[$index]}" "$dim" "${row_note[$index]}" "$plain"
    else
        printf '%s %s%-14s %s%s' "$mark" "$yellow" "${row_label[$index]}" "${row_note[$index]}" "$plain"
    fi
}

if $list_only; then
    for index in "${!row_label[@]}"; do
        if [ "${row_state[$index]}" = ready ]; then
            row_line "$index" " "
        else
            row_line "$index" "-"
        fi
        echo
    done
    exit 0
fi

# Choosing the rows: from what was named, or from the list.

choose_named() {
    local selector lowered platform version index found row
    for selector in "$@"; do
        lowered=$(tr '[:upper:]' '[:lower:]' <<< "$selector")
        platform="${lowered%%-*}"
        version=""
        case "$lowered" in
            *-*) version="${lowered#*-}" ;;
        esac
        found=false
        for index in "${!row_label[@]}"; do
            row=$(tr '[:upper:]' '[:lower:]' <<< "${row_platform[$index]}")
            if [ "$lowered" = all ] && [ "${row_group[$index]}" = extra ]; then
                continue
            fi
            if [ "$lowered" != all ]; then
                [ "$row" = "$platform" ] || continue
                if [ -n "$version" ] && ! version_matches "${row_wanted[$index]}" "$version" \
                    && ! version_matches "${row_version[$index]}" "$version"; then
                    continue
                fi
            fi
            found=true
            # A version that has to be downloaded is run only when it is named itself,
            # or with --download.
            if [ "${row_state[$index]}" != missing ] || $download || [ -n "$version" ]; then
                row_chosen[$index]=true
            fi
        done
        if ! $found; then
            echo "There is no row for \"$selector\". Rows are shown by --list." >&2
            exit 2
        fi
    done
}

choose_from_list() {
    local cursor=0 key rest index lines=$((row_count + 4)) first=true

    restore_terminal() { printf '\033[?25h'; }
    trap 'restore_terminal; exit 130' INT
    printf '\033[?25l'

    while true; do
        if ! $first; then
            printf '\033[%dA' "$lines"
        fi
        first=false
        printf '\033[K%sThe demo%ss UI tests: choose what to run%s\n' "$bold" "'" "$plain"
        printf '\033[K%sup and down to move, space to choose, a for all that are installed, n for none, return to run, q to leave%s\n' "$dim" "$plain"
        printf '\033[K\n'
        for index in "${!row_label[@]}"; do
            local mark="[ ]" pointer="  "
            if [ "${row_chosen[$index]}" = true ]; then mark="[x]"; fi
            if [ "$index" = "$cursor" ]; then pointer="${bold}> ${plain}"; fi
            printf '\033[K%s' "$pointer"
            row_line "$index" "$mark"
            printf '\n'
        done
        printf '\033[K\n'

        IFS= read -rsn1 key || key=q
        case "$key" in
            $'\033')
                read -rsn2 -t 1 rest || rest=""
                case "$rest" in
                    '[A') key=k ;;
                    '[B') key=j ;;
                    *) continue ;;
                esac
                ;;
        esac
        case "$key" in
            k) if [ "$cursor" -gt 0 ]; then cursor=$((cursor - 1)); fi ;;
            j) if [ "$cursor" -lt $((row_count - 1)) ]; then cursor=$((cursor + 1)); fi ;;
            ' ')
                if [ "${row_chosen[$cursor]}" = true ]; then
                    row_chosen[$cursor]=false
                else
                    row_chosen[$cursor]=true
                fi
                ;;
            a)
                for index in "${!row_label[@]}"; do
                    if [ "${row_state[$index]}" != missing ]; then row_chosen[$index]=true; fi
                done
                ;;
            n)
                for index in "${!row_label[@]}"; do row_chosen[$index]=false; done
                ;;
            q)
                restore_terminal
                exit 0
                ;;
            '')
                break
                ;;
        esac
    done
    restore_terminal
    trap - INT
}

if [ ${#selectors[@]} -gt 0 ]; then
    choose_named "${selectors[@]}"
elif [ -t 0 ] && [ -t 1 ]; then
    choose_from_list
else
    echo "Name the rows to run, such as: scripts/run-demo-tests.sh all" >&2
    exit 2
fi

# The versions that were chosen and are not on this Mac are downloaded only after
# asking, or with --download.
to_download=()
for index in "${!row_label[@]}"; do
    if [ "${row_chosen[$index]}" = true ] && [ "${row_state[$index]}" = missing ]; then to_download+=("$index"); fi
done
if [ ${#to_download[@]} -gt 0 ] && ! $download; then
    echo "${bold}These versions are not on this Mac, and are downloaded before the tests:${plain}"
    for index in "${to_download[@]}"; do echo "  ${row_label[$index]}"; done
    echo "Each is several gigabytes, and stays on the Mac afterwards."
    answer=""
    if [ -t 0 ]; then
        read -r -p "Download them? [y/N] " answer
    fi
    case "$answer" in
        y | Y | yes) ;;
        *)
            echo "They are left out. --download downloads them without asking."
            for index in "${to_download[@]}"; do row_chosen[$index]=false; done
            to_download=()
            ;;
    esac
fi

# The rows that were chosen, the Mac app last.
order=()
for index in "${!row_label[@]}"; do
    if [ "${row_chosen[$index]}" = true ] && [ "${row_platform[$index]}" != macOS ]; then order+=("$index"); fi
done
for index in "${!row_label[@]}"; do
    if [ "${row_chosen[$index]}" = true ] && [ "${row_platform[$index]}" = macOS ]; then order+=("$index"); fi
done

if [ ${#order[@]} -eq 0 ]; then
    echo "Nothing was chosen."
    exit 0
fi

# Running the rows.

output="$root/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$output"

row_result=()
row_detail=()
for index in "${!row_label[@]}"; do
    row_result+=("")
    row_detail+=("")
done

child=""
stop() {
    if [ -n "$child" ]; then kill "$child" 2> /dev/null || true; fi
    printf '\n'
    exit 130
}
trap stop INT TERM

destination() {
    local index="$1"
    if [ "${row_platform[$index]}" = macOS ]; then
        echo "platform=macOS"
    else
        echo "platform=${row_platform[$index]} Simulator,id=${row_udid[$index]}"
    fi
}

slug() {
    tr '[:upper:] ' '[:lower:]-' <<< "$1"
}

elapsed() {
    local seconds="$1"
    printf '%dm %02ds' $((seconds / 60)) $((seconds % 60))
}

# Waits for xcodebuild, with a line that says how far it is where the output is a
# terminal. Takes the text to show, and the log to count the tests in or nothing.
wait_for_child() {
    local text="$1" log="${2:-}" started=$SECONDS passed failed
    while kill -0 "$child" 2> /dev/null; do
        if [ -t 1 ]; then
            if [ -n "$log" ]; then
                passed=$(grep -Eci "^Test case .* passed" "$log" || true)
                failed=$(grep -Eci "^Test case .* failed" "$log" || true)
                printf '\r\033[K  %s  %s passed, %s failed  %s' "$text" "$passed" "$failed" "$(elapsed $((SECONDS - started)))"
            else
                printf '\r\033[K  %s  %s' "$text" "$(elapsed $((SECONDS - started)))"
            fi
        fi
        sleep 1
    done
    local status=0
    wait "$child" || status=$?
    child=""
    if [ -t 1 ]; then printf '\r\033[K'; fi
    return "$status"
}

# Downloads the version of a row that is not on this Mac.
download_version() {
    local index="$1" platform="${row_platform[$1]}" label="${row_label[$1]}" log started=$SECONDS
    log="$output/download-$(slug "$label").log"
    local arguments=(-downloadPlatform "$platform")
    case "${row_wanted[$index]}" in
        *.*) arguments+=(-buildVersion "${row_wanted[$index]}") ;;
    esac
    xcodebuild "${arguments[@]}" > "$log" 2>&1 &
    child=$!
    while kill -0 "$child" 2> /dev/null; do
        if [ -t 1 ]; then
            # xcodebuild writes how far it is over the same line.
            printf '\r\033[K  Downloading %s  %s  %s' "$label" "$(elapsed $((SECONDS - started)))" \
                "$(tail -c 300 "$log" | tr '\r' '\n' | tail -n 1 | cut -c 1-80)"
        fi
        sleep 1
    done
    local status=0
    wait "$child" || status=$?
    child=""
    if [ -t 1 ]; then printf '\r\033[K'; fi
    if [ "$status" -ne 0 ]; then
        echo "  ${red}$label could not be downloaded.${plain} The log is $log"
        tr '\r' '\n' < "$log" | tail -n 3 | sed 's/^/    /'
        return 1
    fi
    echo "  Downloaded $label in $(elapsed $((SECONDS - started)))"
}

# Makes a simulator for the version of a row that has none: the usual device of the
# platform, of the newest model the version runs on.
make_simulator() {
    local index="$1" platform="${row_platform[$1]}" label="${row_label[$1]}" version runtime types type
    version=$(installed_version "$platform" "${row_wanted[$index]}" "$runtimes")
    runtime=$(awk -F '\t' -v p="$platform" -v v="$version" '$1 == p && $2 == v { print $3; exit }' <<< "$runtimes")
    types=$(
        xcrun simctl list -j runtimes | jq -r --arg runtime "$runtime" '
            .runtimes[] | select(.identifier == $runtime) | .supportedDeviceTypes[] | [.name, .identifier] | @tsv
        '
    )
    type=$(pick_usual "$platform" "$types")
    if [ -z "$type" ] || ! xcrun simctl create "${type%%	*}" "${type#*	}" "$runtime" > /dev/null; then
        echo "  ${red}No simulator could be made for $label.${plain}"
        return 1
    fi
    echo "  Made the simulator ${type%%	*} for $platform $version"
}

# Gets a row that was chosen ready to run: its version is downloaded if it is
# missing, and a simulator is made if the version has none.
prepare_row() {
    local index="$1"
    if [ "${row_state[$index]}" = missing ]; then
        download_version "$index" || return 1
        read_simulators
        resolve_row "$index"
    fi
    if [ "${row_state[$index]}" = nosimulator ]; then
        make_simulator "$index" || return 1
        read_simulators
        resolve_row "$index"
    fi
    [ "${row_state[$index]}" = ready ]
}

built=""
failed_builds=""

build() {
    local index="$1" platform="${row_platform[$1]}" log
    log="$output/build-$(slug "$platform").log"
    xcodebuild build-for-testing \
        -project "$project" -scheme "$scheme" \
        -destination "$(destination "$index")" \
        -skipMacroValidation -derivedDataPath "$derived_data" \
        > "$log" 2>&1 &
    child=$!
    if wait_for_child "Building for $platform"; then
        built="$built $platform"
    else
        failed_builds="$failed_builds $platform"
        echo "  ${red}The build for $platform failed.${plain} Its log is $log"
        grep -E "error:" "$log" | head -n 5 | sed 's/^/    /' || true
    fi
}

run_row() {
    local index="$1" platform="${row_platform[$1]}" label="${row_label[$1]}"
    local name log bundle started=$SECONDS
    name=$(slug "$label")
    log="$output/$name.log"
    bundle="$output/$name.xcresult"

    local arguments=(
        test-without-building
        -project "$project" -scheme "$scheme"
        -destination "$(destination "$index")"
        -skipMacroValidation -derivedDataPath "$derived_data"
        -resultBundlePath "$bundle"
    )
    # The tests of a Mac app share one pointer and one keyboard, so they cannot run
    # side by side.
    if $serial || [ "$platform" = macOS ]; then
        arguments+=(-testPlan Demo)
    else
        local count="$workers"
        if [ -z "$count" ]; then
            case "$platform" in
                watchOS | visionOS) count=2 ;;
                *) count=3 ;;
            esac
        fi
        arguments+=(-testPlan DemoParallel -parallel-testing-enabled YES -parallel-testing-worker-count "$count")
    fi
    for test in ${only_testing[@]+"${only_testing[@]}"}; do
        arguments+=("-only-testing:$test")
    done

    if [ "$platform" = macOS ] && [ -t 1 ]; then
        echo "  The Mac app's tests take over the pointer and the keyboard. They start in 5 seconds."
        sleep 5
    fi

    xcodebuild "${arguments[@]}" > "$log" 2>&1 &
    child=$!
    local status=0
    wait_for_child "Testing $label" "$log" || status=$?

    local summary passed="" failed="" skipped=""
    if summary=$(xcrun xcresulttool get test-results summary --path "$bundle" 2> /dev/null); then
        passed=$(jq -r '.passedTests' <<< "$summary")
        failed=$(jq -r '.failedTests' <<< "$summary")
        skipped=$(jq -r '.skippedTests' <<< "$summary")
    fi
    local took
    took=$(elapsed $((SECONDS - started)))

    if [ -z "$passed" ]; then
        row_result[$index]=failed
        row_detail[$index]="the tests did not run: see $log"
        echo "  ${red}$label: the tests did not run.${plain} The log is $log"
        tail -n 5 "$log" | sed 's/^/    /'
    elif [ "$status" -eq 0 ] && [ "$failed" = 0 ]; then
        row_result[$index]=passed
        row_detail[$index]="$passed passed, $skipped skipped, in $took"
        echo "  ${green}$label: $passed passed${plain}, $skipped skipped, in $took"
    else
        row_result[$index]=failed
        row_detail[$index]="$failed failed, $passed passed, $skipped skipped, in $took"
        echo "  ${red}$label: $failed failed${plain}, $passed passed, $skipped skipped, in $took"
        jq -r '.testFailures[] | "    \(.testIdentifierString): \(.failureText | split("\n")[0])"' <<< "$summary" | cut -c 1-200 | sort -u
        echo "    The log is $log, and the result bundle is $bundle"
    fi
}

echo "${bold}Running ${#order[@]} of the demo's rows.${plain} Logs and results go to $output"

# Everything that has to be downloaded or made comes first, so that the tests are not
# held up half way.
for index in "${order[@]}"; do
    if [ "${row_state[$index]}" != ready ] && ! prepare_row "$index"; then
        row_result[$index]=failed
        row_detail[$index]="its version could not be downloaded, or no simulator could be made for it"
    fi
done

for index in "${order[@]}"; do
    if [ -n "${row_result[$index]}" ]; then continue; fi
    platform="${row_platform[$index]}"
    case " $built $failed_builds " in
        *" $platform "*) ;;
        *) build "$index" ;;
    esac
    case " $failed_builds " in
        *" $platform "*)
            row_result[$index]=failed
            row_detail[$index]="the build failed"
            continue
            ;;
    esac
    run_row "$index"
done

# What happened, with the rows that could not be run.

echo
echo "${bold}Summary${plain}"
exit_status=0
for index in "${!row_label[@]}"; do
    case "${row_result[$index]}" in
        passed) printf '  %s%-8s%s %-14s %s\n' "$green" "passed" "$plain" "${row_label[$index]}" "${row_detail[$index]}" ;;
        failed)
            exit_status=1
            printf '  %s%-8s%s %-14s %s\n' "$red" "failed" "$plain" "${row_label[$index]}" "${row_detail[$index]}"
            ;;
        *)
            if [ "${row_state[$index]}" != ready ]; then
                printf '  %s%-8s%s %-14s not on this Mac, and not chosen\n' "$yellow" "missing" "$plain" "${row_label[$index]}"
            elif [ "${row_group[$index]}" = wanted ]; then
                printf '  %s%-8s %-14s not chosen%s\n' "$dim" "not run" "${row_label[$index]}" "$plain"
            fi
            ;;
    esac
done
exit "$exit_status"
