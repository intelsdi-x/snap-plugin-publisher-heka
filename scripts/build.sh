#!/bin/bash

# http://www.apache.org/licenses/LICENSE-2.0.txt
# 
# 
# Copyright 2016 Intel Corporation
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -u
set -o pipefail

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__proj_dir="$(dirname "$__dir")"

# shellcheck source=scripts/common.sh
. "${__dir}/common.sh"

plugin_name=${__proj_dir##*/}
build_dir="${__proj_dir}/build"
go_build=(go build -ldflags "-w")

_info "project path: ${__proj_dir}"
_info "plugin name: ${plugin_name}"

mozilla_path=$(echo ${GOPATH//://src/github.com/mozilla-services:}/src/github.com/mozilla-services | cut -d':' -f1)
heka_path="${mozilla_path}/heka"

_debug "heka build path: ${heka_path}"

[[ -d ${heka_path} ]] || _fail "run 'make dep' and ensure mozilla/heka source exist in ${heka_path}"

_info "building heka"
# NOTE: heka buid scripts does not honor set -e and set -u
set +e +u
(cd "${heka_path}" && source ./build.sh)
set -e -u

# append Heka build to GOPATH
export GOPATH="${heka_path}/build/heka:${GOPATH}"
_debug "heka custom GOPATH: ${GOPATH}"

_info "building snap heka plugin"

# Disable CGO for builds
export CGO_ENABLED=0

# rebuild binaries:
_debug "removing: ${build_dir:?}/*"
rm -rf "${build_dir:?}/"*

_info "building plugin: ${plugin_name}"
export GOOS=linux
export GOARCH=amd64
mkdir -p "${build_dir}/${GOOS}/x86_64"
"${go_build[@]}" -o "${build_dir}/${GOOS}/x86_64/${plugin_name}" . || exit 1

export GOOS=darwin
export GOARCH=amd64
mkdir -p "${build_dir}/${GOOS}/x86_64"
"${go_build[@]}" -o "${build_dir}/${GOOS}/x86_64/${plugin_name}" . || exit 1
