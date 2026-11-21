#!/bin/bash
#
# Creates an iPhone simulator that runs a version of iOS, and prints its identifier.
#
# usage: scripts/make-simulator.sh <iOS version>
#
# The version is one that the selected Xcode has a simulator runtime for, such as 17.5,
# or the start of one, such as 17, which takes the newest 17.x that is installed. The
# runtime has to be installed already; this does not download one.
#
# The identifier goes in an xcodebuild destination:
#
#   xcodebuild test -destination "platform=iOS Simulator,id=$(scripts/make-simulator.sh 17.5)" …

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: $0 <iOS version>" >&2
    exit 1
fi

version="$1"

# Prints the identifier of the newest installed runtime for the version, then the
# identifier of an iPhone it supports, or nothing if there is no such runtime.
find_runtime_and_device() {
    xcrun simctl list runtimes --json | VERSION="$version" python3 -c '
import json, os, sys

wanted = os.environ["VERSION"]

def number(version):
    return tuple(int(part) for part in version.split(".") if part.isdigit())

runtimes = [
    runtime for runtime in json.load(sys.stdin)["runtimes"]
    if runtime.get("isAvailable", False)
    and runtime.get("name", "").startswith("iOS ")
    and (runtime["version"] == wanted or runtime["version"].startswith(wanted + "."))
]
if not runtimes:
    sys.exit(0)
runtime = max(runtimes, key=lambda runtime: number(runtime["version"]))

phones = [
    device for device in runtime.get("supportedDeviceTypes", [])
    if device.get("productFamily") == "iPhone"
]
if not phones:
    sys.exit("error: the " + runtime["name"] + " runtime does not support any iPhone")

# An ordinary iPhone with a number for a name, such as "iPhone 15", and the newest of
# those. Failing that, whichever iPhone the runtime lists first.
def model(device):
    words = device["name"].split()
    return int(words[1]) if len(words) == 2 and words[1].isdigit() else -1

phone = max(phones, key=model) if any(model(phone) >= 0 for phone in phones) else phones[0]

print(runtime["identifier"])
print(phone["identifier"])
'
}

found="$(find_runtime_and_device)"

if [ -z "$found" ]; then
    echo "error: there is no iOS $version simulator runtime for the selected Xcode. Installed:" >&2
    xcrun simctl list runtimes >&2 || true
    exit 1
fi

runtime="$(echo "$found" | sed -n 1p)"
device_type="$(echo "$found" | sed -n 2p)"

xcrun simctl create "UITesting iOS $version" "$device_type" "$runtime"
