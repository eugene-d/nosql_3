import csv
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DATA_DIR = SCRIPT_DIR / "data" / "ml-1m"
OUT_DIR = SCRIPT_DIR / "import"

OUT_DIR.mkdir(exist_ok=True)

# movies -- витягуємо рік з назви "Toy Story (1995)"
import re
with open(DATA_DIR / "movies.dat", encoding="latin-1") as fin, \
     open(OUT_DIR / "movies.csv", "w", newline="", encoding="utf-8") as fout:
    w = csv.writer(fout)
    w.writerow(["movieId", "title", "genres", "year"])
    for line in fin:
        parts = line.strip().split("::")
        yr = ""
        m = re.search(r'\((\d{4})\)', parts[1])
        if m:
            yr = m.group(1)
        w.writerow(parts + [yr])

print("movies.csv OK")

# -- ratings.dat -> ratings.csv
cnt = 0
with open(DATA_DIR / "ratings.dat", encoding="latin-1") as fin, \
     open(OUT_DIR / "ratings.csv", "w", newline="", encoding="utf-8") as fout:
    w = csv.writer(fout)
    w.writerow(["userId", "movieId", "rating", "timestamp"])
    for line in fin:
        parts = line.strip().split("::")
        w.writerow(parts)
        cnt += 1

print(f"ratings.csv OK ({cnt} rows)")

# -- users.dat -> users.csv
with open(DATA_DIR / "users.dat", encoding="latin-1") as fin, \
     open(OUT_DIR / "users.csv", "w", newline="", encoding="utf-8") as fout:
    w = csv.writer(fout)
    w.writerow(["userId", "gender", "age", "occupation"])
    for line in fin:
        parts = line.strip().split("::")
        w.writerow(parts[:4])  # zip not needed

print("users.csv OK")
