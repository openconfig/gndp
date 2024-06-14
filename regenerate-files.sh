#!/bin/bash
set -euo pipefail

BASE=$(bazel info bazel-genfiles)
GNSI_NS='github.com/openconfig/gndp'

copy_generated() {
  pkg="$1"
  # Default to using package name for proto if $2 is unset
  proto="$1" && [ "${2++}" ] && proto="$2"
  # Bazel go_rules will create empty files containing "// +build ignore\n\npackage ignore"
  # in the case where the protoc compiler doesn't generate any output. See:
  # https://github.com/bazelbuild/rules_go/blob/03a8b8e90eebe699d7/go/tools/builders/protoc.go#L190
  for file in "${BASE}"/proto/"${proto}"_go_proto_/"${GNSI_NS}"/proto/"${pkg}"/*.pb.go; do
    [[ $(head -n 1 "${file}") == "// +build ignore" ]] || (cp "${file}" "proto/${pkg}"/ && chmod u+w,-x "proto/${pkg}"/"$(basename "${file}")")
  done
}

bazel build //proto:all
copy_generated "gndp"