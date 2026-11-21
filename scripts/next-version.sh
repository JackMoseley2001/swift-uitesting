#!/bin/bash
#
# Works out the version of the next release from the last one and what has changed.
#
# usage: scripts/next-version.sh <last version, or "none"> <change> [label ...]
#
# The change is one of:
#   patch      Fixes and small improvements: 1.2.3 becomes 1.2.4.
#   feature    Something new that does not break existing code: 1.2.3 becomes 1.3.0.
#   breaking   A change that existing code has to adapt to: 1.2.3 becomes 2.0.0.
#   labels     The largest of the three found among the labels that follow, or patch
#              if none of them is there.
#   <version>  An exact version, such as 1.0.0. It has to be later than the last one.
#
# Before 1.0.0, a breaking change raises the middle number, as a feature does: 0.3.1
# becomes 0.4.0. Version 1.0.0 is only ever released by asking for it exactly.
#
# With no release yet, the next version is 0.1.0 unless an exact one is asked for.
#
# Prints the next version, without a prefix, which is how Swift packages are tagged.

set -euo pipefail

fail() {
    echo "error: $1" >&2
    exit 1
}

is_version() {
    [[ "$1" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
}

[ $# -ge 2 ] || fail "usage: $0 <last version, or \"none\"> <patch|feature|breaking|labels|version> [label ...]"

last="$1"
change="$2"
shift 2

if [ "$last" != "none" ]; then
    is_version "$last" || fail "the last version, '$last', is not three numbers separated by full stops"
fi

if [ "$change" = "labels" ]; then
    change="patch"
    for label in "$@"; do
        case "$label" in
            breaking) change="breaking" ;;
            feature) [ "$change" = "breaking" ] || change="feature" ;;
        esac
    done
fi

if is_version "$change"; then
    next="$change"
    if [ "$last" != "none" ]; then
        newest="$(printf '%s\n%s\n' "$last" "$next" | sort -t . -k 1,1n -k 2,2n -k 3,3n | tail -n 1)"
        if [ "$next" = "$last" ] || [ "$newest" != "$next" ]; then
            fail "version $next is not later than the last release, $last"
        fi
    fi
    echo "$next"
    exit 0
fi

case "$change" in
    patch | feature | breaking) ;;
    *) fail "'$change' is not patch, feature, breaking, labels or a version such as 1.0.0" ;;
esac

if [ "$last" = "none" ]; then
    echo "0.1.0"
    exit 0
fi

IFS=. read -r major minor patch <<< "$last"

case "$change" in
    patch)
        patch=$((patch + 1))
        ;;
    feature)
        minor=$((minor + 1))
        patch=0
        ;;
    breaking)
        if [ "$major" -eq 0 ]; then
            minor=$((minor + 1))
        else
            major=$((major + 1))
            minor=0
        fi
        patch=0
        ;;
esac

echo "$major.$minor.$patch"
