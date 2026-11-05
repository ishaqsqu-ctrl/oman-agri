"""Build the map's offline environment layer for Oman.

Usage:
  python -m pipeline.build_map --worldclim DIR --outline OMN-ADM0.geojson [--out app/assets/map]

Inputs (downloaded separately, see pipeline/README.md):
  * WorldClim 2.1, 2.5 arc-minute (~4.5 km): wc2.1_2.5m_{tavg,tmin,tmax,elev}.zip
    Fick & Hijmans (2017), CC BY 4.0, https://www.worldclim.org/data/worldclim21.html
  * Oman outline: geoBoundaries gbOpen OMN ADM0 (OpenStreetMap, ODbL 1.0)

Outputs (in --out):
  * oman_env.json grid header (origin, cell size, size, sources) and "cells": one array per
        land cell inside Oman: [col, row, elev_m, tavg×12, tmin×12, tmax×12] (°C × 10, integers)
  * oman_outline.json simplified outline polygons [[[lon, lat], ...], ...]
"""
import argparse
import json
from pathlib import Path

import numpy as np
import rasterio
from rasterio.windows import from_bounds
from shapely import contains_xy
from shapely.geometry import shape, mapping

PAD = 0.1  # degrees around the outline's bounding box


def _read(zip_path: Path, member: str, bounds):
    with rasterio.open(f"/vsizip/{zip_path}/{member}") as src:
        win = from_bounds(*bounds, transform=src.transform).round_offsets().round_lengths()
        data = src.read(1, window=win, masked=True)
        return data.astype("float64").filled(np.nan), src.window_transform(win)


def build(worldclim: Path, outline_path: Path, out: Path) -> dict:
    outline = shape(json.loads(outline_path.read_text())["features"][0]["geometry"])
    minx, miny, maxx, maxy = outline.bounds
    bounds = (minx - PAD, miny - PAD, maxx + PAD, maxy + PAD)

    elev, transform = _read(worldclim / "wc2.1_2.5m_elev.zip", "wc2.1_2.5m_elev.tif", bounds)
    layers = {}
    for v in ("tavg", "tmin", "tmax"):
        layers[v] = np.stack([
            _read(worldclim / f"wc2.1_2.5m_{v}.zip", f"wc2.1_2.5m_{v}_{m:02d}.tif", bounds)[0]
            for m in range(1, 13)
        ])
        assert layers[v].shape[1:] == elev.shape, v

    rows, cols = elev.shape
    res = transform.a
    lon = transform.c + (np.arange(cols) + 0.5) * res
    lat = transform.f + (np.arange(rows) + 0.5) * transform.e
    lon2, lat2 = np.meshgrid(lon, lat)
    inside = contains_xy(outline, lon2, lat2)
    valid = inside & np.isfinite(elev)
    for v in layers.values():
        valid &= np.all(np.isfinite(v), axis=0)

    out.mkdir(parents=True, exist_ok=True)
    cells = []
    for r, c in zip(*np.nonzero(valid)):
        temps = [int(round(layers[v][m, r, c] * 10)) for v in ("tavg", "tmin", "tmax") for m in range(12)]
        cells.append([int(c), int(r), int(round(elev[r, c])), *temps])
    n = len(cells)

    header = {
        "origin_lon": transform.c,
        "origin_lat": transform.f,
        "cell_deg": res,
        "cols": cols,
        "rows": rows,
        "cells": n,
        "record": "[col, row, elev_m, tavg x12, tmin x12, tmax x12] (temperatures in degC x10)",
        "sources": {
            "climate": "WorldClim 2.1, 1970-2000 monthly normals, 2.5 arc-min (Fick & Hijmans 2017), CC BY 4.0",
            "elevation": "WorldClim 2.1 elevation (from SRTM), 2.5 arc-min, CC BY 4.0",
            "outline": "geoBoundaries OMN ADM0 (OpenStreetMap contributors), ODbL 1.0",
        },
    }
    (out / "oman_env.json").write_text(json.dumps({**header, "cells": cells}, separators=(",", ":")) + "\n")

    simple = outline.simplify(0.01, preserve_topology=True)
    polys = [simple] if simple.geom_type == "Polygon" else list(simple.geoms)
    rings = [[[round(x, 3), round(y, 3)] for x, y in p.exterior.coords] for p in polys if p.area > 1e-4]
    (out / "oman_outline.json").write_text(json.dumps(rings, separators=(",", ":")) + "\n")
    return header


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--worldclim", type=Path, required=True)
    ap.add_argument("--outline", type=Path, required=True)
    ap.add_argument("--out", type=Path, default=Path("app/assets/map"))
    a = ap.parse_args(argv)
    h = build(a.worldclim, a.outline, a.out)
    print(f"{h['cells']} land cells, grid {h['cols']}x{h['rows']} at {h['cell_deg']:.5f} deg")


if __name__ == "__main__":
    main()
