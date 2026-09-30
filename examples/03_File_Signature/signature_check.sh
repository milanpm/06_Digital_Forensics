#!/usr/bin/env bash

detect_actual_type() {
    local file_name="$1"
    local signature
    local mime_type

    signature=$(xxd -p -l 8 "$file_name" | tr -d '\n')
    mime_type=$(file --brief --mime-type "$file_name")

    case "$signature" in
        89504e470d0a1a0a*) echo "PNG" ;;
        ffd8ff*)         echo "JPEG" ;;
        25504446*)       echo "PDF" ;;
        504b0304*)       echo "ZIP_CONTAINER" ;;
        4d5a*)           echo "PE_EXECUTABLE" ;;
        47494638*)       echo "GIF" ;;
        *)
            if [[ "$mime_type" == text/* ]]; then
                echo "TEXT"
            else
                echo "UNKNOWN"
            fi
            ;;
    esac
}

detect_expected_type() {
    local file_name="$1"
    local extension

    extension="${file_name##*.}"
    extension=$(printf '%s' "$extension" | tr '[:upper:]' '[:lower:]')

    case "$extension" in
        png)            echo "PNG" ;;
        jpg|jpeg)       echo "JPEG" ;;
        pdf)            echo "PDF" ;;
        zip|docx|xlsx|pptx)
                        echo "ZIP_CONTAINER" ;;
        exe|dll)        echo "PE_EXECUTABLE" ;;
        gif)            echo "GIF" ;;
        txt|md|csv)     echo "TEXT" ;;
        *)              echo "UNKNOWN" ;;
    esac
}

printf '%-22s %-15s %-15s %s\n' \
    "FILE" "EXPECTED" "ACTUAL" "STATUS"

printf '%-22s %-15s %-15s %s\n' \
    "----------------------" "---------------" "---------------" "--------"

for file_name in "$@"; do
    if [[ ! -f "$file_name" ]]; then
        printf '%-22s %s\n' "$file_name" "ERROR: file not found"
        continue
    fi

    expected_type=$(detect_expected_type "$file_name")
    actual_type=$(detect_actual_type "$file_name")

    if [[ "$expected_type" == "UNKNOWN" ]]; then
        status="REVIEW"
    elif [[ "$expected_type" == "$actual_type" ]]; then
        status="MATCH"
    else
        status="MISMATCH"
    fi

    printf '%-22s %-15s %-15s %s\n' \
        "$file_name" "$expected_type" "$actual_type" "$status"
done
