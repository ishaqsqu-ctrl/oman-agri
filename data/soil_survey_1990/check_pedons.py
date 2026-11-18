"""Check each pedon's location against the JOG 1:250 000 sheet in its field id and
against Oman's land grid. Writes pedons_checked.csv with decimal degrees and a status.

Sheet code: NE = 16-20 N, NF = 20-24 N; zone 39 = 48-54 E, 40 = 54-60 E; sheets 1-16
run in rows of four from the north-west corner, each 1 degree by 1.5 degrees."""
import csv, json, re, sys
from pathlib import Path

HERE = Path(__file__).parent
ROOT = HERE.parents[1]


def dms(s):
    m = re.match(r"(\d+)°(\d+)'([NE])", s)
    return int(m[1]) + int(m[2]) / 60


def sheet_box(fid):
    m = re.search(r"N([EF]) (39|40)-(\d+)", fid)
    if not m:
        return None
    top = {"E": 20, "F": 24}[m[1]]
    left = {"39": 48, "40": 54}[m[2]]
    n = int(m[3]) - 1
    lat1 = top - n // 4
    lon0 = left + 1.5 * (n % 4)
    return (lat1 - 1, lat1, lon0, lon0 + 1.5)


def on_land(lat, lon, env):
    h = env
    col = int((lon - h["origin_lon"]) / h["cell_deg"])
    row = int((h["origin_lat"] - lat) / h["cell_deg"])
    # One cell of tolerance: coordinates are given to the minute (1.8 km) and
    # the grid's coastline is 4.6 km coarse.
    return any((col + dc, row + dr) in env["_cells"] for dc in (-1, 0, 1) for dr in (-1, 0, 1))


def main():
    env = json.loads((ROOT / "app/assets/map/oman_env.json").read_text())
    hdr = env["header"] if "header" in env else env
    hdr["_cells"] = {(c[0], c[1]) for c in env["cells"]}
    rows = list(csv.DictReader(open(HERE / "pedons.csv", encoding="utf-8")))
    out = []
    for r in rows:
        lat, lon = dms(r["lat_dms"]), dms(r["lon_dms"])
        box = sheet_box(r["field_id"])
        land = on_land(lat, lon, hdr)
        if box is None:
            status = "no_sheet" if land else "off_land"
        else:
            inside = box[0] <= lat <= box[1] and box[2] <= lon <= box[3]
            status = "verified" if inside and land else ("sheet_mismatch" if not inside else "off_land")
        out.append({"pedon": r["pedon"], "lat": round(lat, 4), "lon": round(lon, 4), "status": status})
        print(r["pedon"], r["lat_dms"], r["lon_dms"], r["field_id"], box, status)
    with open(HERE / "pedons_checked.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["pedon", "lat", "lon", "status"])
        w.writeheader()
        w.writerows(out)


if __name__ == "__main__":
    sys.exit(main())
