#!/usr/bin/env bash
set -Eeuo pipefail

readonly ARTIFACT_ROOT="${CLIR_ROOT:-/artifact}"
readonly OUTPUT_ROOT="${CLIR_OUTPUT:-/output}"
readonly DB_ROOT="${CLIR_DB_ROOT:-/tmp/clir-mongodb}"
readonly DB_PATH="${DB_ROOT}/data"
readonly DB_LOG="${DB_ROOT}/mongod.log"
readonly DB_PID="${DB_ROOT}/mongod.pid"
readonly DB_PORT=27017

db_started=0

log() {
    printf '[CLIR] %s\n' "$*"
}

cleanup() {
    if [[ "${db_started}" -eq 1 && -f "${DB_PID}" ]]; then
        kill "$(cat "${DB_PID}")" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

start_database() {
    if [[ "${db_started}" -eq 1 ]]; then
        return
    fi

    mkdir -p "${DB_PATH}"
    log "Starting the bundled MongoDB service on 127.0.0.1:${DB_PORT}"
    mongod \
        --bind_ip 127.0.0.1 \
        --dbpath "${DB_PATH}" \
        --fork \
        --logappend \
        --logpath "${DB_LOG}" \
        --pidfilepath "${DB_PID}" \
        --port "${DB_PORT}" \
        --quiet
    db_started=1

    log "Restoring the packaged IR corpus"
    local attempt
    for attempt in $(seq 1 30); do
        if mongorestore \
            --drop \
            --quiet \
            --host 127.0.0.1 \
            --port "${DB_PORT}" \
            --db cranelift \
            "${ARTIFACT_ROOT}/mongodb_ir"; then
            log "Database is ready"
            return
        fi
        sleep 1
    done

    log "MongoDB initialization failed; log follows:"
    sed -n '1,200p' "${DB_LOG}" >&2
    return 1
}

run_single() {
    local num_cases="$1"
    local config_path="$2"
    local output_path="$3"

    mkdir -p "${output_path}"
    log "Generating ${num_cases} target-specific case(s) with ${config_path}"
    clir --num "${num_cases}" single "${config_path}" "${output_path}"
    "${ARTIFACT_ROOT}/scripts/validate_output.sh" \
        single "${num_cases}" "${output_path}"
}

run_compatible() {
    local num_cases="$1"
    local output_path="$2"

    mkdir -p "${output_path}"
    log "Generating ${num_cases} compatible case(s) for four backends"
    clir --num "${num_cases}" compatible \
        "${ARTIFACT_ROOT}/configs/arch_x86.toml" \
        "${ARTIFACT_ROOT}/configs/arch_aarch64.toml" \
        "${ARTIFACT_ROOT}/configs/arch_riscv64.toml" \
        "${ARTIFACT_ROOT}/configs/arch_s390x.toml" \
        "${output_path}"
    "${ARTIFACT_ROOT}/scripts/validate_output.sh" \
        compatible "${num_cases}" "${output_path}"
}

run_smoke_test() {
    local output_path="${OUTPUT_ROOT}/smoke-test"

    start_database
    log "Running the smoke test (expected duration: under 5 minutes)"
    run_single 1 "${ARTIFACT_ROOT}/configs/arch_x86.toml" "${output_path}"
    log "Smoke test passed"
    log "Output: ${output_path}"
}

run_reduced() {
    local num_cases="${1:-10}"
    local base_path="${OUTPUT_ROOT}/reduced"

    start_database
    log "Running the reduced evaluation with ${num_cases} case(s) per mode"
    run_single \
        "${num_cases}" \
        "${ARTIFACT_ROOT}/configs/arch_x86.toml" \
        "${base_path}/single-x86"
    run_compatible "${num_cases}" "${base_path}/compatible"
    log "Reduced evaluation passed"
    log "Output: ${base_path}"
}

run_full() {
    local num_cases="${1:-1000}"
    local base_path="${OUTPUT_ROOT}/full"

    start_database
    log "Running the full generation experiment with ${num_cases} case(s) per mode"
    run_single \
        "${num_cases}" \
        "${ARTIFACT_ROOT}/configs/arch_x86.toml" \
        "${base_path}/single-x86"
    run_compatible "${num_cases}" "${base_path}/compatible"
    log "Full generation experiment passed"
    log "Output: ${base_path}"
}

usage() {
    cat <<'EOF'
CLIR ISSTA 2026 artifact

Usage:
  docker run ... clir-artifact:issta2026 COMMAND [ARGS]

Commands:
  smoke-test
      Generate and validate one target-specific case (3 CLIF files).
  reduced [NUM_CASES]
      Run both modes with 10 cases by default (150 CLIF files).
  full [NUM_CASES]
      Run both modes with 1,000 cases by default (15,000 CLIF files).
  single [NUM_CASES] [CONFIG] [OUTPUT]
      Run target-specific mode. Defaults: 1, arch_x86.toml, /output/single.
  compatible [NUM_CASES] [OUTPUT]
      Run compatible mode for all four packaged profiles.
  validate MODE NUM_CASES OUTPUT
      Validate an existing single or compatible output directory.
  shell
      Start MongoDB, restore the corpus, and open a shell.
  raw CLIR_ARGS...
      Start MongoDB and invoke the clir binary directly.
  help
      Show this message.
EOF
}

command="${1:-help}"
shift || true

case "${command}" in
    help|-h|--help)
        usage
        ;;
    smoke-test)
        run_smoke_test
        ;;
    reduced)
        run_reduced "${1:-10}"
        ;;
    full)
        run_full "${1:-1000}"
        ;;
    single)
        start_database
        run_single \
            "${1:-1}" \
            "${2:-${ARTIFACT_ROOT}/configs/arch_x86.toml}" \
            "${3:-${OUTPUT_ROOT}/single}"
        ;;
    compatible)
        start_database
        run_compatible "${1:-1}" "${2:-${OUTPUT_ROOT}/compatible}"
        ;;
    validate)
        exec "${ARTIFACT_ROOT}/scripts/validate_output.sh" "$@"
        ;;
    shell)
        start_database
        cd "${ARTIFACT_ROOT}"
        exec /bin/bash
        ;;
    raw)
        start_database
        exec clir "$@"
        ;;
    *)
        log "Unknown command: ${command}"
        usage >&2
        exit 2
        ;;
esac
