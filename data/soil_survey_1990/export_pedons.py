"""Write app/assets/map/pedons.json: the verified pedons with short Arabic and English
summaries. Run check_pedons.py first."""
import csv, json
from pathlib import Path

HERE = Path(__file__).parent
ROOT = HERE.parents[1]

# Great groups (USDA Soil Taxonomy, 1987 edition used by the atlas), in plain words.
GROUPS = {
    "Calciorthids": ("تربة صحراوية جيرية", "Desert soil with lime"),
    "Gypsiorthids": ("تربة صحراوية جبسية", "Desert soil with gypsum"),
    "Salorthids": ("تربة ملحية (سبخة)", "Salt soil (sabkha)"),
    "Camborthids": ("تربة صحراوية قليلة التطور", "Weakly developed desert soil"),
    "Torripsamments": ("تربة رملية", "Sandy soil"),
    "Torrifluvents": ("تربة رسوبية من فيضانات الأودية", "Flood-deposited (alluvial) soil"),
    "Torriorthents": ("تربة حديثة قليلة التطور", "Young, little-developed soil"),
    "Ustropepts": ("تربة طينية في منطقة الخريف", "Clay soil of the monsoon zone"),
}
LANDFORMS = {
    "alluvial terrace": ("مصطبة رسوبية", "alluvial terrace"),
    "alluvial plain": ("سهل رسوبي", "alluvial plain"),
    "pediplain": ("سهل حتّي", "pediplain"),
    "sabkha": ("سبخة", "sabkha"),
    "plateau": ("هضبة", "plateau"),
    "sand plain": ("سهل رملي", "sand plain"),
    "marine terrace": ("مصطبة بحرية", "marine terrace"),
}


USES = {
    "Cultivated: banana, alfalfa and Rhodes grass under surface irrigation":
        "أرض مزروعة: موز وبرسيم وحشيشة رودس بالري السطحي",
    "Farm: date palm, alfalfa and sorghum under surface irrigation":
        "مزرعة: نخيل وبرسيم وذرة رفيعة بالري السطحي",
    "Cultivated with date palm under surface irrigation": "مزروعة بالنخيل بالري السطحي",
}


def group(tax):
    for k, v in GROUPS.items():
        if k in tax:
            return k, v
    raise ValueError(tax)


def landform(phys):
    p = phys.lower()
    for k, v in sorted(LANDFORMS.items(), key=lambda kv: -len(kv[0])):
        if k in p:
            return v
    raise ValueError(phys)


def main():
    rows = {r["pedon"]: r for r in csv.DictReader(open(HERE / "pedons.csv", encoding="utf-8"))}
    checked = list(csv.DictReader(open(HERE / "pedons_checked.csv", encoding="utf-8")))
    out = []
    for c in checked:
        if c["status"] != "verified":
            continue
        r = rows[c["pedon"]]
        tax = r["taxonomy_usda"]
        gg, (gar, gen) = group(tax)
        lar, len_ = landform(r["physiography"])
        fao = r["fao_1988"]
        traits = [t for t, hit in [
            ("saline", "saline" in tax or "salic" in fao or "Solonchak" in fao),
            ("sodic", "sodic" in tax or "Sodic" in fao),
            ("shallow", "Lithic" in tax),
            ("gravelly", "skeletal" in tax),
            ("gypsum_pan", "Petrogypsic" in tax),
        ] if hit]
        out.append({
            "n": int(c["pedon"]), "lat": float(c["lat"]), "lon": float(c["lon"]),
            "group": gg, "soil_ar": gar, "soil_en": gen, "land_ar": lar, "land_en": len_,
            "slope": r["slope_pct"], "usda": tax, "fao": r["fao_1988"], "traits": traits,
            "use_en": r["land_use"], "use_ar": USES[r["land_use"]] if r["land_use"] else "",
        })
    dst = ROOT / "app/assets/map/pedons.json"
    dst.write_text(json.dumps({
        "source": "General Soil Map of the Sultanate of Oman, Ministry of Agriculture and Fisheries with FAO, 1990",
        "pedons": out,
    }, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{len(out)} pedons -> {dst}")


if __name__ == "__main__":
    main()
