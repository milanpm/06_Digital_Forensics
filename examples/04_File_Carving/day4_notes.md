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

A file extension alone does not guarantee the actual file type. The actual contents can be examined using tools such as:

```bash
file sample.png
xxd sample.png
sha256sum sample.png
```

The PNG file signature is:

```text
89 50 4E 47 0D 0A 1A 0A
```

The sample PNG used in this exercise was 68 bytes.

Its SHA-256 hash was:

```text
431ced6916a2a21a156e38701afe55bbd7f88969fbbfc56d7fe099d47f265460
```

Day 3 answered the question:

> What type of file is this data?

Day 4 extends that idea:

> Can the file be located and extracted from raw binary data?

## 3. What Is File Carving?

File carving is a technique for extracting files from raw data by examining file signatures and file structures rather than relying only on filenames or filesystem metadata.

A simplified carving workflow is:

```text
Raw Data
   |
   v
Find File Signature
   |
   v
Determine Start Offset
   |
   v
Determine File Boundary
   |
   v
Extract Data
   |
   v
Validate Recovered File
```

This approach can be useful when filenames or filesystem metadata are missing, damaged, or no longer reference the original file.

## 4. Preparing the Original PNG

The PNG created during Day 3 was reused.

```bash
cp ../03_File_Signature/sample.png original.png
```

The file was examined with:

```bash
file original.png
ls -l original.png
sha256sum original.png
xxd original.png
```

The result showed:

```text
File size : 68 bytes
File type : PNG image data, 1 x 1, 8-bit gray+alpha, non-interlaced
```

The beginning of the file contained:

```text
89 50 4E 47 0D 0A 1A 0A
```

The final portion contained the PNG `IEND` chunk and CRC:

```text
49 45 4E 44 AE 42 60 82
```

## 5. Creating a Synthetic Disk Image

To practice file carving, a small raw binary image was created.

First, unrelated data was generated before and after the PNG.

```bash
head -c 100 /dev/zero > prefix.bin
head -c 50 /dev/zero > suffix.bin
```

The files were combined:

```bash
cat prefix.bin original.png suffix.bin > disk_image.bin
```

The layout was:

```text
100 bytes prefix
68 bytes PNG
50 bytes suffix
```

Therefore:

```text
100 + 68 + 50 = 218 bytes
```

The raw image was examined with:

```bash
file disk_image.bin
xxd disk_image.bin
```

`file` reported the raw image simply as:

```text
data
```

This happened because the PNG signature was not located at offset 0.

## 6. Finding the PNG Start Offset

The hex dump contained:

```text
00000060: 0000 0000 8950 4e47 0d0a 1a0a ...
```

The PNG signature begins after four bytes on the line starting at `0x60`.

Therefore:

```text
0x60 + 0x04 = 0x64
```

Hexadecimal `0x64` is decimal 100.

```text
PNG start offset = 100
```

An important distinction is:

> An offset represents a position in the data.

## 7. Finding the PNG End Offset

Near the end of the PNG, the hex dump showed:

```text
000000a0: 4945 4e44 ae42 6082 ...
```

The final byte `82` was located at `0xA7`, which is decimal 167.

Therefore:

```text
Start offset = 100
End offset   = 167
```

The file size is:

```text
167 - 100 + 1 = 68 bytes
```

The `+1` is necessary because both offset 100 and offset 167 are included.

For example, offsets `0, 1, 2, 3` represent four bytes, not three.

Another way to think about the same range is:

```text
Next offset after file = 168
168 - 100 = 68 bytes
```

The key idea is:

> Offset = position, while size = number of bytes.

## 8. Manual File Carving with dd

The PNG was manually extracted using `dd`.

```bash
dd if=disk_image.bin of=recovered.png bs=1 skip=100 count=68
```

The options mean:

```text
if=disk_image.bin   Input file
of=recovered.png    Output file
bs=1                Process one byte per block
skip=100            Skip the first 100 bytes
count=68            Copy 68 bytes
```

The result showed:

```text
68+0 records in
68+0 records out
68 bytes copied
```

The recovered file was checked:

```bash
file recovered.png
```

Result:

```text
PNG image data, 1 x 1, 8-bit gray+alpha, non-interlaced
```

This demonstrated manual byte-level file carving.

## 9. Verifying the Manual Recovery

The original and recovered files were hashed.

```bash
sha256sum original.png recovered.png
```

Both produced:

```text
431ced6916a2a21a156e38701afe55bbd7f88969fbbfc56d7fe099d47f265460
```

Because this was a controlled experiment with a known original file, the matching hashes demonstrated that the recovered file was byte-for-byte identical to the original.

## 10. Automating Signature Detection with Python

Manual offset calculation works for learning, but a carver should be able to search the raw data automatically.

The PNG signatures were represented as Python byte strings:

```python
PNG_HEADER = b"\x89\x50\x4e\x47\x0d\x0a\x1a\x0a"
PNG_END = b"\x49\x45\x4e\x44\xae\x42\x60\x82"
```

The entire image was loaded:

```python
data = Path(IMAGE_FILE).read_bytes()
```

The header was searched using:

```python
start = data.find(PNG_HEADER)
```

Result:

```text
PNG start offset : 100
```

The end sequence was searched using:

```python
end_signature = data.find(PNG_END, start)
```

Result:

```text
PNG end signature: 160
```

The value 160 represents the position of the first byte of the searched end sequence:

```text
Offset 160 : 49
Offset 161 : 45
Offset 162 : 4E
Offset 163 : 44
Offset 164 : AE
Offset 165 : 42
Offset 166 : 60
Offset 167 : 82
```

Therefore:

```python
end = end_signature + len(PNG_END)
```

produced:

```text
end = 168
```

## 11. Understanding Python Slicing

The PNG data was extracted with:

```python
carved_data = data[start:end]
```

For this example:

```python
data[100:168]
```

Python includes the starting position but excludes the ending position.

Therefore, the actual extracted offsets are:

```text
100 through 167
```

The number of bytes is:

```text
168 - 100 = 68
```

This provides a useful alternative to the inclusive `+1` calculation used when describing the first and last byte offsets.

## 12. Limitation of the First Python Carver

The first program searched for only one PNG header:

```python
start = data.find(PNG_HEADER)
```

This works when the raw image contains only one target file.

However, a real disk image can contain many files. To demonstrate this limitation, a second raw image was created containing two copies of the PNG.

The first version recovered only the first matching PNG, showing that a single `find()` call was insufficient for multiple-file recovery.

## 13. Creating a Multi-File Test Image

The following command created a raw image containing two PNG files:

```bash
cat \
  prefix.bin \
  original.png \
  suffix.bin \
  original.png \
  suffix.bin \
  > disk_image_multi.bin
```

The total size was:

```text
100 + 68 + 50 + 68 + 50 = 336 bytes
```

The layout was:

```text
Offsets 0-99
    Prefix: 100 bytes

Offsets 100-167
    PNG #1: 68 bytes

Offsets 168-217
    Gap: 50 bytes

Offsets 218-285
    PNG #2: 68 bytes

Offsets 286-335
    Suffix: 50 bytes
```

## 14. Recovering Multiple PNG Files

The carver was modified to repeatedly search for PNG signatures.

The key variables were:

```python
search_offset = 0
file_count = 0
```

The search was placed inside a loop:

```python
while True:
    start = data.find(PNG_HEADER, search_offset)

    if start == -1:
        break
```

After recovering a PNG:

```python
search_offset = end
```

moves the next search beyond the file that was just recovered.

The first search found:

```text
Start offset = 100
End offset   = 167
```

The next search began at offset 168 and found the second PNG at:

```text
Start offset = 218
End offset   = 285
```

When no additional PNG header was found, `find()` returned `-1` and the loop ended.

## 15. Automatic Output File Names

Recovered files were named using:

```python
output_file = f"recovered_{file_count:03d}.png"
```

The format specification `:03d` means:

- decimal integer
- width of three digits
- pad unused positions with zeros

Examples:

```text
1  -> 001
2  -> 002
10 -> 010
```

Therefore the recovered files were:

```text
recovered_001.png
recovered_002.png
```

## 16. Multiple File Carving Result

Running the final carver produced:

```text
[PNG #1]
Start offset : 100
End offset   : 167
Size         : 68 bytes
Output       : recovered_001.png

[PNG #2]
Start offset : 218
End offset   : 285
Size         : 68 bytes
Output       : recovered_002.png

Total recovered PNG files: 2
```

The raw image layout was:

```text
disk_image_multi.bin (336 bytes)

0-99       Prefix (100 bytes)
100-167    PNG #1 (68 bytes)
168-217    Gap (50 bytes)
218-285    PNG #2 (68 bytes)
286-335    Suffix (50 bytes)
```

## 17. Final Validation

Both recovered files were checked using:

```bash
file recovered_001.png recovered_002.png
```

Result:

```text
recovered_001.png: PNG image data, 1 x 1, 8-bit gray+alpha, non-interlaced
recovered_002.png: PNG image data, 1 x 1, 8-bit gray+alpha, non-interlaced
```

Their sizes were checked:

```bash
wc -c original.png recovered_001.png recovered_002.png
```

Result:

```text
 68 original.png
 68 recovered_001.png
 68 recovered_002.png
204 total
```

SHA-256 verification:

```bash
sha256sum original.png recovered_001.png recovered_002.png
```

Result:

```text
431ced6916a2a21a156e38701afe55bbd7f88969fbbfc56d7fe099d47f265460  original.png
431ced6916a2a21a156e38701afe55bbd7f88969fbbfc56d7fe099d47f265460  recovered_001.png
431ced6916a2a21a156e38701afe55bbd7f88969fbbfc56d7fe099d47f265460  recovered_002.png
```

Finally, byte-by-byte comparison was performed:

```bash
cmp original.png recovered_001.png
echo "PNG #1 cmp result: $?"

cmp original.png recovered_002.png
echo "PNG #2 cmp result: $?"
```

Result:

```text
PNG #1 cmp result: 0
PNG #2 cmp result: 0
```

A `cmp` exit status of `0` means that the compared files are identical.

Therefore, both recovered PNG files were byte-for-byte identical to the known original used in this controlled experiment.

## 18. Important Forensic Interpretation

In this exercise, `original.png` was available because the raw disk image was deliberately constructed from known data.

Therefore, the recovered files could be compared directly against the original.

In a real forensic investigation, the original file may not be available. In that situation, recovery validation may instead involve:

- checking the detected file type
- parsing the file structure
- opening or decoding the recovered file
- checking for structural corruption
- recording the recovered file's cryptographic hash

The newly calculated hash can then serve as an integrity reference for the recovered evidence.

## 19. Limitations of the Simple Carver

The Python program created in this exercise is an educational file carver, not a production forensic recovery tool.

Important limitations include:

- It assumes recognizable PNG signatures.
- It assumes the target file is stored contiguously.
- It searches for a simple end sequence.
- False-positive signatures are possible.
- Corrupted files may contain a header without a valid ending.
- Different file formats require different recovery logic.
- Some formats cannot be reliably carved using only a header and footer.
- Filesystem information is not considered.

One of the most important limitations is fragmentation.

A file might conceptually be stored as:

```text
PNG Header
    |
PNG Fragment A

[Unrelated Data]

PNG Fragment B
    |
IEND
```

A simple header-to-footer search cannot reliably reconstruct such a file.

Professional forensic recovery may therefore require both file-format knowledge and filesystem analysis.

## 20. Key Takeaways

1. A filename or extension does not prove the actual file type.
2. File signatures can identify data inside raw binary content.
3. An offset represents a byte position.
4. File size represents the number of bytes.
5. File carving requires identifying file boundaries.
6. `dd` can perform manual byte-level extraction.
7. Python `bytes.find()` can automate signature searching.
8. Python slicing uses an exclusive end position.
9. Repeated searches can recover multiple embedded files.
10. Recovered data should always be validated.
11. SHA-256 can be used as an integrity reference.
12. Simple signature-based carving has important real-world limitations.

## 21. Learning Progress

The first four Digital Forensics exercises now form a connected sequence:

```text
Day 1 — Evidence Integrity
        |
        | SHA-256 / integrity verification
        v
Day 2 — File Metadata
        |
        | timestamps and metadata
        v
Day 3 — File Signature
        |
        | magic bytes and actual file type
        v
Day 4 — File Carving
        |
        | signature-based extraction and recovery
        v
Next Step
```

Day 3 provided the signature knowledge required to locate embedded files.

Day 1 provided the integrity techniques used to verify the recovered files.

Day 4 combined these concepts into a basic recovery workflow.

## Next Step

### Day 5 — Deleted Files and Filesystem Recovery

The next exercise will move from signature-based carving toward understanding deleted files from a filesystem perspective.

Topics will include:

- What happens when a file is deleted
- File metadata versus file content
- Allocated and unallocated space
- Why deleted data can sometimes remain recoverable
- Why writing new data can destroy recoverable evidence
- The relationship between filesystem recovery and file carving
