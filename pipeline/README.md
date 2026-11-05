# pipeline/

Offline processing that builds data files for the app. Not run on phones.

## build_map.py — environment layer for the Map tab

Downloads (place them in one folder, e.g. `~/data/worldclim`):

| File | Source | Licence |
|---|---|---|
| `wc2.1_2.5m_{tavg,tmin,tmax,elev}.zip` | WorldClim 2.1, https://geodata.ucdavis.edu/climate/worldclim/2_1/base/ (Fick & Hijmans 2017, 1970–2000 normals) | CC BY 4.0 |
| `geoBoundaries-OMN-ADM0.geojson` | geoBoundaries gbOpen OMN ADM0 (OpenStreetMap contributors) | ODbL 1.0 |

Run from the repository root:

```
pip install rasterio shapely numpy
python -m pipeline.build_map --worldclim ~/data/worldclim --outline geoBoundaries-OMN-ADM0.geojson
```

It writes `app/assets/map/oman_env.bin` (one record per ~4.5 km land cell: elevation and monthly
mean, minimum and maximum temperature), `oman_env.json` (grid header and sources) and
`oman_outline.json` (simplified outline). The app computes suitability on the device from these
and each crop's requirements (`app/lib/features/map/suitability.dart`).

Not used: the geoBoundaries wilayat layer (ADM2, "Oman National Geographic Structure") because its
licence is "direct permission" to geoBoundaries and it predates the 2022 wilayats; and its ADM1
layer, which follows an older 7-region division.
