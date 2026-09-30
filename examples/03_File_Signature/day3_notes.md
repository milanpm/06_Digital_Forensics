# Digital Forensics Day 3
## File Signatures and Hexadecimal Analysis

## 1. Learning Objectives

- Understand the difference between a file extension and its actual format.
- Examine file contents in hexadecimal form.
- Identify common file signatures, also called magic bytes.
- Detect files with misleading extensions.
- Compare files using SHA-256 hashes.
- Automate signature checking with a Bash script.

## 2. Key Concepts

### File Extension

A file extension is part of a file name that suggests its format.

Examples:

- `.txt`: text file
- `.jpg`: JPEG image
- `.png`: PNG image
- `.pdf`: PDF document

Extensions can be changed without modifying file contents. Therefore, an
extension alone is not reliable evidence of a file's actual type.

### File Signature

A file signature is a characteristic byte sequence stored inside a file.
Forensic examination uses these bytes to identify the probable file type.

| Format | Signature |
|---|---|
| JPEG | `FF D8 FF` |
| PNG | `89 50 4E 47 0D 0A 1A 0A` |
| PDF | `25 50 44 46` |
| ZIP | `50 4B 03 04` |
| Windows EXE/DLL | `4D 5A` |
| GIF | `47 49 46 38` |

## 3. Hexadecimal Analysis

The following command displays a file in hexadecimal form:

```bash
xxd evidence.txt
```

The output consists of:

- Offset: byte position within the file
- Hexadecimal bytes: raw file data
- ASCII representation: printable characters

The first eight bytes can be displayed with:

```bash
xxd -l 8 -g 1 evidence.txt
```

## 4. Extension Mismatch Experiment

`evidence.txt` was copied to `disguised_image.jpg`.

Although the copied file used the `.jpg` extension, the `file` command
identified it as ASCII text.

```text
evidence.txt:        ASCII text
disguised_image.jpg: ASCII text
```

The first bytes were identical:

```text
44 69 67 69 74 61 6C 20
```

These bytes represent the ASCII text `Digital `, not the JPEG signature
`FF D8 FF`.

## 5. PNG Signature Analysis

A 1 x 1 PNG file was created and copied to `hidden_image.txt`.

Both files began with:

```text
89 50 4E 47 0D 0A 1A 0A
```

The PNG header contained:

- `49 48 44 52`: `IHDR` chunk
- `00 00 00 01`: width of 1 pixel
- `00 00 00 01`: height of 1 pixel
- `08`: 8-bit depth
- `04`: grayscale with alpha
- `00`: non-interlaced

The `file` command identified both files as PNG images despite their different
extensions.

## 6. SHA-256 Verification

The following file pairs had identical SHA-256 values:

```text
evidence.txt = disguised_image.jpg
sample.png   = hidden_image.txt
```

This proves that changing a file name or extension does not necessarily change
the file contents.

## 7. Automated Signature Analysis

The `signature_check.sh` Bash script:

1. Extracts the file extension.
2. Reads the first eight bytes.
3. Determines the expected type from the extension.
4. Determines the probable actual type from the signature.
5. Reports `MATCH`, `MISMATCH`, or `REVIEW`.

Results:

```text
evidence.txt           TEXT            TEXT            MATCH
disguised_image.jpg    JPEG            TEXT            MISMATCH
sample.png             PNG             PNG             MATCH
hidden_image.txt       TEXT            PNG             MISMATCH
```

## 8. Forensic Interpretation

A `MISMATCH` result does not prove that a file is malicious. It indicates that
the file requires further investigation.

Reliable file identification should combine:

- File extension
- File signature
- Internal file structure
- MIME type
- Metadata
- Cryptographic hashes
- Context of file discovery

A matching signature does not guarantee that the entire file is valid.
Signatures can be forged, and damaged or truncated files may be misidentified.

## 9. Conclusion

File extensions are labels, not proof of file type. File signatures and
internal structures provide stronger evidence, while SHA-256 hashes establish
whether two files contain identical bytes.
