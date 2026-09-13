# Day 1 — Forensics Basics and Evidence Integrity

Author: Alex

## Objectives

- Understand original preservation and working-copy analysis.
- Calculate SHA-256 hashes.
- Detect file-content changes.
- Record reproducible observations.

## Environment

- Windows
- Git Bash
- Git branch: main
- Repository setting: core.autocrlf=false

## Lab Data

The evidence file contains synthetic patient information.
No real patient data was used.

## Results

### Original SHA-256

b4ee5e69660fc0348e20aaf4ff84f9dfe0afadfedd1d0dee2fdd8bbe5dd76f0f

### Working Copy Before Modification

Its SHA-256 matched the original.
The cmp command produced no output, confirming identical contents.

### Working Copy After Modification

Added line:

Status: Reviewed

SHA-256:

c8d7b5d8a2b49d9c5df33a8cdb7f81c711bbf559500752ea07f98021b89ef23b

### Original Verification After Modification

Command:

sha256sum -c evidence.sha256

Result:

evidence.txt: OK

## Conclusions

- The initial working copy had identical contents to the original.
- Modifying the working copy changed its hash.
- The original file still matched its recorded hash.

## Limitations

- A content hash does not verify all filesystem metadata.
- A matching hash alone does not establish provenance or authenticity.
- This exercise does not constitute a complete chain-of-custody record.
- The original was preserved by procedure, not by a write blocker.

## Next Step

Day 2 — File Metadata and Timestamp Analysis
