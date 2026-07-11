import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from neo4j import GraphDatabase

SCRIPT_DIR = Path(__file__).resolve().parent
load_dotenv(SCRIPT_DIR / ".env")

URI = os.environ["NEO4J_URI"]
USER = os.environ["NEO4J_USER"]
PWD = os.environ["NEO4J_PASSWORD"]


def run_file(fpath):
    text = Path(fpath).read_text(encoding="utf-8")

    # розбиваємо по ; ігноруючи коментарі (/* */ не повністю)
    stmts = []
    buf = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("//") or stripped.startswith("/*") or stripped == "":
            continue
        buf.append(line)
        if stripped.endswith(";"):
            stmts.append("\n".join(buf).rstrip(";").strip())
            buf = []
    if buf:
        stmts.append("\n".join(buf).strip())

    drv = GraphDatabase.driver(URI, auth=(USER, PWD))
    with drv.session() as sess:
        for i, stmt in enumerate(stmts, 1):
            if not stmt:
                continue
            short = stmt[:80].replace("\n", " ")
            print(f"\n--- query {i}: {short}...")
            try:
                res = sess.run(stmt)
                records = list(res)
                if records:
                    keys = records[0].keys()
                    for rec in records:
                        print(dict(rec))
                summary = res.consume()
                cnt = summary.counters
                if cnt.nodes_created or cnt.relationships_created or cnt.indexes_added:
                    print(f"  +{cnt.nodes_created} nodes, "
                          f"+{cnt.relationships_created} rels, "
                          f"+{cnt.indexes_added} indexes")
            except Exception as e:
                print(f"  ERROR: {e}")
    drv.close()
    print("\nDone.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python run_cypher.py <file.cypher>")
        sys.exit(1)
    run_file(sys.argv[1])
