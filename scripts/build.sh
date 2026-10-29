#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

output="bin/GarminFace.prg"
if [[ "${1:-}" == "--tests" ]]; then
    shift
    output="bin/GarminFaceTests.prg"
    set -- -t "$@"
fi

# Use an explicit SDK, the current SDK Manager selection, or PATH.
compiler=""
if [[ -n "${CIQ_SDK_HOME:-}" ]]; then
    compiler="$CIQ_SDK_HOME/bin/monkeyc"
else
    for config in \
        "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg" \
        "$HOME/.Garmin/ConnectIQ/current-sdk.cfg"; do
        if [[ -f "$config" ]]; then
            sdk_path="$(tr -d '\r\n' < "$config")"
            if [[ -x "$sdk_path/bin/monkeyc" ]]; then
                compiler="$sdk_path/bin/monkeyc"
                break
            fi
        fi
    done
    if [[ -z "$compiler" ]]; then
        compiler="$(command -v monkeyc || true)"
    fi
fi

if [[ -z "$compiler" || ! -x "$compiler" ]]; then
    printf '%s\n' \
        'Brakuje Connect IQ SDK. Zainstaluj SDK i urządzenie fr955 przez SDK Manager.' \
        'W razie potrzeby ustaw CIQ_SDK_HOME na folder SDK (zawierający bin/monkeyc).' \
        'Szczegóły: README.md' >&2
    exit 1
fi

key_path="${CIQ_DEVELOPER_KEY:-$PROJECT_ROOT/.keys/developer_key.der}"
if [[ ! -f "$key_path" ]]; then
    printf '%s\n' \
        'Brakuje klucza podpisującego. Uruchom: bash scripts/generate-key.sh' \
        'Istniejący klucz można wskazać zmienną CIQ_DEVELOPER_KEY.' >&2
    exit 1
fi

mkdir -p bin
"$compiler" -f monkey.jungle -d fr955 -o "$output" -y "$key_path" "$@"
printf '%s\n' "Gotowe: $PROJECT_ROOT/$output"
