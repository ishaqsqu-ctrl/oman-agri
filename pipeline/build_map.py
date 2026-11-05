"""Build the map's offline environment layer for Oman.

Usage:
  python -m pipeline.build_map --worldclim DIR --soilgrids DIR --hwsd DIR --outline OMN-ADM0.geojson [--out app/assets/map]

Inputs (downloaded separately, see pipeline/README.md):
  * WorldClim 2.1, 2.5 arc-minute (~4.5 km): wc2.1_2.5m_{tavg,tmin,tmax,elev}.zip
    Fick & Hijmans (2017), CC BY 4.0, https://www.worldclim.org/data/worldclim21.html
  * SoilGrids 2.0 aggregated 5 km means, {sand,silt,clay,phh2o}_{0-5,5-15,15-30}cm_mean_5000.tif
    Poggio et al. (2021), ISRIC, CC BY 4.0, https://files.isric.org/soilgrids/latest/data_aggregated/5000m/
  * HWSD v2.0 (FAO & IIASA 2023), HWSD2.bil/.hdr raster and HWSD2.mdb database (needs mdb-export,
    from mdbtools), CC BY-NC-SA 3.0 IGO: soil electrical conductivity ELEC_COND (dS/m)
  * Oman outline: geoBoundaries gbOpen OMN ADM0 (OpenStreetMap, ODbL 1.0)

Outputs (in --out):
  * oman_env.json grid header (origin, cell size, size, sources) and "cells": one array per
        land cell inside Oman: [col, row, elev_m, tavg×12, tmin×12, tmax×12, sand, silt, clay, ph, ec]
        (°C × 10; sand/silt/clay in g/kg and pH × 10 for the top 30 cm; ec = soil salinity in
        dS/m × 10 for the top 30 cm; -1 where the source has no value)
  * oman_outline.json simplified outline polygons [[[lon, lat], ...], ...]
"""
import argparse
import json
from pathlib import Path

import numpy as np
import rasterio
from rasterio.warp import transform as warp_transform
from rasterio.windows import from_bounds
from shapely import contains_xy
from shapely.geometry import shape, mapping

PAD = 0.1  # degrees around the outline's bounding box


def _read(zip_path: Path, member: str, bounds):
    with rasterio.open(f"/vsizip/{zip_path}/{member}") as src:
        win = from_bounds(*bounds, transform=src.transform).round_offsets().round_lengths()
        data = src.read(1, window=win, masked=True)
        return data.astype("float64").filled(np.nan), src.window_transform(win)


SOIL_DEPTHS = (("0-5", 5), ("5-15", 10), ("15-30", 15))  # cm, thickness


def _soil(soilgrids: Path, lon: np.ndarray, lat: np.ndarray) -> dict:
    """Depth-weighted 0–30 cm means at the given points (SoilGrids mapped units:
    g/kg for sand, silt, clay; pH × 10). NaN where any depth has no value."""
    out = {}
    for prop in ("sand", "silt", "clay", "phh2o"):
        acc = np.zeros(lon.shape)
        for depth, w in SOIL_DEPTHS:
            with rasterio.open(soilgrids / f"{prop}_{depth}cm_mean_5000.tif") as src:
                xs, ys = warp_transform("EPSG:4326", src.crs, lon.tolist(), lat.tolist())
                band = src.read(1)
                r, c = rasterio.transform.rowcol(src.transform, xs, ys)
                r, c = np.asarray(r), np.asarray(c)
                ok = (r >= 0) & (r < band.shape[0]) & (c >= 0) & (c < band.shape[1])
                v = np.full(lon.shape, np.nan)
                v[ok] = band[r[ok], c[ok]]
                v[v == src.nodata] = np.nan
                acc += v * w
        out[prop] = acc / sum(w for _, w in SOIL_DEPTHS)
    return out


def _hwsd_ec_by_smu(mdb: Path) -> dict:
    """Top-30 cm soil EC (dS/m) per HWSD2 soil mapping unit: the share-weighted
    mean of each layer over the unit's soils, then D1 (0–20 cm) and D2 (20–40 cm)
    weighted 2:1. Negative ELEC_COND values mean "no data" and are skipped."""
    import csv
    import io
    import subprocess

    rows = subprocess.run(["mdb-export", str(mdb), "HWSD2_LAYERS"], check=True, capture_output=True,
                          text=True).stdout
    acc: dict = {}
    for r in csv.DictReader(io.StringIO(rows)):
        if r["LAYER"] not in ("D1", "D2") or r["ELEC_COND"] in ("", None):
            continue
        ec, share = float(r["ELEC_COND"]), float(r["SHARE"] or 0)
        if ec < 0 or share <= 0:
            continue
        a = acc.setdefault(int(r["HWSD2_SMU_ID"]), {"D1": [0.0, 0.0], "D2": [0.0, 0.0]})[r["LAYER"]]
        a[0] += ec * share
        a[1] += share
    out = {}
    for smu, layers in acc.items():
        vals = [(layers[d][0] / layers[d][1], w) for d, w in (("D1", 2), ("D2", 1)) if layers[d][1] > 0]
        if vals:
            out[smu] = sum(v * w for v, w in vals) / sum(w for _, w in vals)
    return out


def _hwsd_ec(hwsd: Path, transform, rows: int, cols: int) -> np.ndarray:
    """Mean soil EC of the HWSD 30-arc-second pixels inside each map cell."""
    ec_by_smu = _hwsd_ec_by_smu(hwsd / "HWSD2.mdb")
    res = transform.a
    left, top = transform.c, transform.f
    bounds = (left, top - rows * res, left + cols * res, top)
    with rasterio.open(hwsd / "HWSD2.bil") as src:
        win = from_bounds(*bounds, transform=src.transform).round_offsets().round_lengths()
        smu = src.read(1, window=win)
        nodata = src.nodata
    k = round(res / (1 / 120))  # map cell / 30 arc-seconds
    lut = np.vectorize(lambda u: ec_by_smu.get(int(u), np.nan), otypes=[float])
    uniq = np.unique(smu)
    table = dict(zip(uniq.tolist(), lut(uniq).tolist()))
    vals = np.vectorize(lambda u: np.nan if u == nodata else table[int(u)], otypes=[float])(smu)
    out = np.full((rows, cols), np.nan)
    for r in range(rows):
        for c in range(cols):
            block = vals[r * k:(r + 1) * k, c * k:(c + 1) * k]
            if block.size and np.isfinite(block).any():
                out[r, c] = np.nanmean(block)
    return out


def build(worldclim: Path, outline_path: Path, out: Path, soilgrids: Path | None = None,
          hwsd: Path | None = None) -> dict:
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
    rr, cc = np.nonzero(valid)
    soil = _soil(soilgrids, lon[cc], lat[rr]) if soilgrids else None
    ec = _hwsd_ec(hwsd, transform, rows, cols) if hwsd else None

    def sv(prop, i):
        if soil is None or not np.isfinite(soil[prop][i]):
            return -1
        return int(round(soil[prop][i]))

    cells = []
    for i, (r, c) in enumerate(zip(rr, cc)):
        temps = [int(round(layers[v][m, r, c] * 10)) for v in ("tavg", "tmin", "tmax") for m in range(12)]
        cells.append([int(c), int(r), int(round(elev[r, c])), *temps,
                      sv("sand", i), sv("silt", i), sv("clay", i), sv("phh2o", i),
                      int(round(ec[r, c] * 10)) if ec is not None and np.isfinite(ec[r, c]) else -1])
    n = len(cells)

    header = {
        "origin_lon": transform.c,
        "origin_lat": transform.f,
        "cell_deg": res,
        "cols": cols,
        "rows": rows,
        "cells": n,
        "record": "[col, row, elev_m, tavg x12, tmin x12, tmax x12, sand, silt, clay, ph, ec] "
                  "(temperatures degC x10; sand/silt/clay g/kg, pH x10 and EC dS/m x10, 0-30 cm; -1 = no value)",
        "sources": {
            "climate": "WorldClim 2.1, 1970-2000 monthly normals, 2.5 arc-min (Fick & Hijmans 2017), CC BY 4.0",
            "elevation": "WorldClim 2.1 elevation (from SRTM), 2.5 arc-min, CC BY 4.0",
            "soil": "SoilGrids 2.0 (Poggio et al. 2021, ISRIC), 5 km aggregated means, 0-30 cm, CC BY 4.0",
            "salinity": "HWSD v2.0 (FAO & IIASA 2023), ELEC_COND, 0-30 cm, CC BY-NC-SA 3.0 IGO",
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
    ap.add_argument("--soilgrids", type=Path)
    ap.add_argument("--hwsd", type=Path)
    ap.add_argument("--out", type=Path, default=Path("app/assets/map"))
    a = ap.parse_args(argv)
    h = build(a.worldclim, a.outline, a.out, a.soilgrids, a.hwsd)
    print(f"{h['cells']} land cells, grid {h['cols']}x{h['rows']} at {h['cell_deg']:.5f} deg")


if __name__ == "__main__":
    main()
