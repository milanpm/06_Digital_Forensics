"""
Simple Multiple PNG File Carver
Digital Forensics Day 4
"""

from pathlib import Path

IMAGE_FILE = "disk_image_multi.bin"

PNG_HEADER = b"\x89\x50\x4e\x47\x0d\x0a\x1a\x0a"
PNG_END = b"\x49\x45\x4e\x44\xae\x42\x60\x82"

data = Path(IMAGE_FILE).read_bytes()

search_offset = 0
file_count = 0

while True:
    # Find the next PNG header.
    start = data.find(PNG_HEADER, search_offset)

    if start == -1:
        break

    # Find the PNG end signature after this header.
    end_signature = data.find(PNG_END, start)

    if end_signature == -1:
        print(f"PNG header found at {start}, but no end signature found.")
        break

    end = end_signature + len(PNG_END)

    carved_data = data[start:end]

    file_count += 1

    output_file = f"recovered_{file_count:03d}.png"
    Path(output_file).write_bytes(carved_data)

    print(f"[PNG #{file_count}]")
    print(f"Start offset : {start}")
    print(f"End offset   : {end - 1}")
    print(f"Size         : {len(carved_data)} bytes")
    print(f"Output       : {output_file}")
    print()

    # Continue searching after the recovered PNG.
    search_offset = end

print(f"Total recovered PNG files: {file_count}")
