# Day 4 — File Carving: File Extraction and Recovery Using File Signatures

- Date: 2026-10-02
- Topic: File Carving
- Status: Completed

## 1. Learning Objectives

- Understand the basic concept of file carving.
- Identify file boundaries using file signatures.
- Understand byte offsets in hexadecimal dumps.
- Extract a file manually using `dd`.
- Implement a simple PNG carver using Python.
- Recover multiple embedded PNG files.
- Verify recovered files using file type, size, SHA-256, and byte comparison.

## 2. Review of Day 3

Day 3 focused on file signatures and magic bytes.

A file extension alone does not guarantee the actual file type.
The contents of a file can be examined using tools such as:

```bash
file sample.png
xxd sample.png
sha256sum sample.png
