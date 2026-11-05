# pipeline/

Offline processing that builds data files for the app. Not run on phones.

## build_map.py — environment layer for the Map tab

Downloads (place them in one folder, e.g. `~/data/worldclim`):

| File | Source | Licence |
|---|---|---|
| `wc2.1_2.5m_{tavg,tmin,tmax,elev}.zip` | WorldClim 2.1, https://geodata.ucdavis.edu/climate/worldclim/2_1/base/ (Fick & Hijmans 2017, 1970–2000 normals) | CC BY 4.0 |
| `{sand,silt,clay,phh2o}_{0-5,5-15,15-30}cm_mean_5000.tif` | SoilGrids 2.0 aggregated 5 km means, https://files.isric.org/soilgrids/latest/data_aggregated/5000m/ (Poggio et al. 2021, ISRIC) | CC BY 4.0 |
| `HWSD2_RASTER.zip` (→ `HWSD2.bil`, `.hdr`) and `HWSD2_DB.zip` (→ `HWSD2.mdb`) | Harmonized World Soil Database v2.0, https://s3.eu-west-1.amazonaws.com/data.gaezdev.aws.fao.org/HWSD/ (FAO & IIASA 2023) | CC BY-NC-SA 3.0 IGO (non-commercial) |
| `geoBoundaries-OMN-ADM0.geojson` | geoBoundaries gbOpen OMN ADM0 (OpenStreetMap contributors) | ODbL 1.0 |

Run from the repository root:

```
apt install mdbtools   # reads HWSD2.mdb
pip install rasterio shapely numpy
python -m pipeline.build_map --worldclim ~/data/worldclim --soilgrids ~/data/soilgrids --hwsd ~/data/hwsd --outline geoBoundaries-OMN-ADM0.geojson
```

It writes `app/assets/map/oman_env.json` (grid header, sources, and one record per ~4.5 km land
cell: elevation, monthly mean, minimum and maximum temperature, and the top-30 cm depth-weighted
sand, silt, clay and pH, and the HWSD soil salinity ECe in dS/m) and
`oman_outline.json` (simplified outline). The app computes suitability on the device from these
and each crop's requirements (`app/lib/features/map/suitability.dart`).

Not used: the geoBoundaries wilayat layer (ADM2, "Oman National Geographic Structure") because its
licence is "direct permission" to geoBoundaries and it predates the 2022 wilayats; and its ADM1
layer, which follows an older 7-region division.

Soil caveat: SoilGrids is a global 5 km model. In Oman it under-represents pure sand (sand stays
38–63 % even under the Wahiba Sands), so the texture layer is mostly "loam". The app therefore shows
soil as conditions beside the climate score, not inside it, and tells the farmer to test their soil.

Salinity: HWSD v2.0 `ELEC_COND` (dS/m) of layers D1 (0–20 cm) and D2 (20–40 cm), weighted by each
soil unit's component share and combined 2:1 for the top 30 cm; each map cell is the mean of the
~1 km HWSD pixels inside it. HWSD rests on older national soil maps, and salinity in Oman changes
quickly with irrigation and well-water quality, so the app shows it as a condition against the crop's
ECe threshold (FAO 29), not inside the score. The HWSD licence is **non-commercial**
(CC BY-NC-SA 3.0 IGO): a paid or commercial release needs permission from FAO or another source.
