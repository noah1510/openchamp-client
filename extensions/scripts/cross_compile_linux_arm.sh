#!/bin/bash

# This script handles the cross compilation of the extensions.

# check if pwd is the root of the extensions
if [ "$(pwd)" != "$(dirname $0)/../.." ]; then
    cd "$(dirname $0)/../.."
fi

# setup the docker container
cd extensions/cross_compile_stuff
docker build -t openchamp_aarch64_cross .
docker run openchamp_aarch64_cross > linux-aarch64
chmod +x linux-aarch64
cd ../..

CROSS_SCTIPT=extensions/cross_compile_stuff/linux-aarch64

# get the build mode
build_mode="Debug"
if [ "$1" == "release" ]; then
    build_mode="Release"
fi

build_mode_lower=$(echo $build_mode | tr '[:upper:]' '[:lower:]')
build_dir="extensions/build_aarch64_$build_mode_lower"

# cross compile the extensions as release
./$CROSS_SCTIPT cmake -GNinja -B "$build_dir" -DCMAKE_BUILD_TYPE="$build_mode" extensions
./$CROSS_SCTIPT ninja -C "$build_dir"
./$CROSS_SCTIPT ninja -C "$build_dir" install
