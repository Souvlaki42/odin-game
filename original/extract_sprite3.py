from pathlib import Path
from zipfile import ZipFile
import json
import re
import shutil
import sys


def safe_filename(name):
    # Prevent path traversal and invalid filenames
    name = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", name)
    name = name.strip().strip(".")
    return name or "unnamed"


def unique_path(path):
    if not path.exists():
        return path

    counter = 2
    while True:
        candidate = path.with_name(
            f"{path.stem}_{counter}{path.suffix}"
        )
        if not candidate.exists():
            return candidate
        counter += 1


def extract_sprite3(sprite_path, output_dir):
    output_dir.mkdir(parents=True, exist_ok=True)

    with ZipFile(sprite_path) as archive:
        # The JSON file is normally sprite.json
        json_name = next(
            name for name in archive.namelist()
            if name.endswith(".json")
        )

        sprite = json.loads(archive.read(json_name))

        # Extract costumes
        for costume in sprite.get("costumes", []):
            archive_name = costume.get("md5ext")

            if not archive_name:
                asset_id = costume["assetId"]
                data_format = costume["dataFormat"]
                archive_name = f"{asset_id}.{data_format}"

            if archive_name not in archive.namelist():
                print(f"Missing costume asset: {archive_name}")
                continue

            original_name = safe_filename(costume["name"])
            extension = Path(archive_name).suffix
            destination = unique_path(
                output_dir / f"{original_name}{extension}"
            )

            with archive.open(archive_name) as source, \
                 destination.open("wb") as target:
                shutil.copyfileobj(source, target)

            print(f"Costume: {archive_name} -> {destination.name}")

        # Extract sounds
        for sound in sprite.get("sounds", []):
            archive_name = sound.get("md5ext")

            if not archive_name:
                asset_id = sound["assetId"]
                data_format = sound["dataFormat"]
                archive_name = f"{asset_id}.{data_format}"

            if archive_name not in archive.namelist():
                print(f"Missing sound asset: {archive_name}")
                continue

            original_name = safe_filename(sound["name"])
            extension = Path(archive_name).suffix
            destination = unique_path(
                output_dir / f"{original_name}{extension}"
            )

            with archive.open(archive_name) as source, \
                 destination.open("wb") as target:
                shutil.copyfileobj(source, target)

            print(f"Sound: {archive_name} -> {destination.name}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python extract_sprite3.py sprite.sprite3 output_dir")
        sys.exit(1)

    extract_sprite3(
        Path(sys.argv[1]),
        Path(sys.argv[2])
    )
