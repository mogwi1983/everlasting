from pathlib import Path
import shutil

source = Path("dist")
destination = Path("docs")
required = {"index.html", "index.js", "index.wasm", "index.pck"}
missing = sorted(name for name in required if not (source / name).is_file())
if missing:
    raise SystemExit("Missing Web export files: " + ", ".join(missing))
destination.mkdir(parents=True, exist_ok=True)
for name in (
    "index.html", "index.js", "index.wasm", "index.pck", "index.png",
    "index.icon.png", "index.apple-touch-icon.png", "index.audio.worklet.js",
    "index.audio.position.worklet.js", "THIRD_PARTY_NOTICES.txt",
    "open-source-licenses.html",
):
    file = source / name
    if file.is_file():
        shutil.copy2(file, destination / name)
print(f"Staged portable Godot export in {destination}")
