#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
key_dir="$PROJECT_ROOT/.keys"
key_path="$key_dir/developer_key.der"

if [[ -e "$key_path" ]]; then
    printf '%s\n' 'Klucz już istnieje; pozostawiam go bez zmian.'
    exit 0
fi

umask 077
mkdir -p "$key_dir"
temporary_key="$(mktemp "$key_dir/private.XXXXXX")"
trap 'rm -f "$temporary_key"' EXIT
openssl genrsa -out "$temporary_key" 4096
openssl pkcs8 -topk8 -inform PEM -outform DER \
    -in "$temporary_key" -out "$key_path" -nocrypt
printf '%s\n' "Utworzono klucz: $key_path" \
    'Zachowaj jego kopię. W VS Code ustaw Monkey C: Developer Key Path na ten plik.'
