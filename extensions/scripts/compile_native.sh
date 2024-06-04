#!/bin/bash

# This script handles the cross compilation of the extensions.

# check if pwd is the root of the extensions
if [ "$(pwd)" != "$(dirname $0)/../.." ]; then
    cd "$(dirname $0)/../.."
fi

# make sure cmake and ninja are installed
if ! command -v cmake &> /dev/null; then
    echo "cmake could not be found"
    exit 1
fi

if ! command -v ninja &> /dev/null; then
    echo "ninja could not be found"
    exit 1
fi

# get the build mode
build_mode="Debug"
if [ "$1" == "release" ]; then
    build_mode="Release"
fi

build_mode_lower=$(echo $build_mode | tr '[:upper:]' '[:lower:]')
build_dir="extensions/build_$build_mode_lower"

# cross compile the extensions as release
cmake -GNinja -B "$build_dir" -DCMAKE_BUILD_TYPE="$build_mode" extensions
ninja -C "$build_dir"
ninja -C "$build_dir" install
