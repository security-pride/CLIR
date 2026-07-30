#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$#" -ne 3 ]]; then
    echo "Usage: validate_output.sh MODE NUM_CASES OUTPUT" >&2
    exit 2
fi

readonly mode="$1"
readonly num_cases="$2"
readonly output_path="$3"

if ! [[ "${num_cases}" =~ ^[1-9][0-9]*$ ]]; then
    echo "NUM_CASES must be a positive integer: ${num_cases}" >&2
    exit 2
fi

case "${mode}" in
    single)
        expected_files=$((num_cases * 3))
        ;;
    compatible)
        expected_files=$((num_cases * 3 * 4))
        for arch in x86_64 aarch64 riscv64 s390x; do
            if [[ ! -d "${output_path}/${arch}" ]]; then
                echo "Missing architecture directory: ${output_path}/${arch}" >&2
                exit 1
            fi
        done
        ;;
    *)
        echo "MODE must be 'single' or 'compatible': ${mode}" >&2
        exit 2
        ;;
esac

actual_files="$(find "${output_path}" -type f -name '*.clif' | wc -l | tr -d ' ')"
if [[ "${actual_files}" -ne "${expected_files}" ]]; then
    echo "Expected ${expected_files} CLIF files, found ${actual_files}" >&2
    exit 1
fi

empty_file="$(find "${output_path}" -type f -name '*.clif' -size 0 -print -quit)"
if [[ -n "${empty_file}" ]]; then
    echo "Generated an empty CLIF file: ${empty_file}" >&2
    exit 1
fi

for level in none speed speed_and_size; do
    matching_file="$(find "${output_path}" -type f -name "*_${level}.clif" -print -quit)"
    if [[ -z "${matching_file}" ]]; then
        echo "No output found for optimization level: ${level}" >&2
        exit 1
    fi
done

directive_file="$(
    find "${output_path}" -type f -name '*.clif' \
        -exec grep -q '^test .*optimize' {} \; -print -quit
)"
if [[ -z "${directive_file}" ]]; then
    echo "Generated files do not contain a Cranelift optimize test directive" >&2
    exit 1
fi

printf '[CLIR] Validation passed: %s non-empty CLIF files in %s\n' \
    "${actual_files}" "${output_path}"
