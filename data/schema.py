"""Column specs per CSV file. Headers equal DB column names
(supabase/migrations/20261103000001_core_knowledge.sql)."""

STATUSES = ("draft", "reviewed", "published")
CATEGORIES = ("vegetable", "fruit", "legume", "cereal", "forage", "ornamental", "medicinal_aromatic", "tree")
LIFECYCLES = ("annual", "perennial", "tree")
SOURCE_TYPES = ("ministry", "university", "fao", "peer_reviewed", "dataset", "other")
STAGES = ("initial", "development", "mid", "late")
TEXTURES = ("sand", "loam", "clay")

META = ["status", "source_id", "source_page", "reviewed_by", "reviewed_at"]

# kind: text | int | num | enum:<NAME> | enums:<NAME> (pipe-separated array)
# A column is required when its DB column is NOT NULL.
# (column, kind, required)
COLUMNS: dict[str, list[tuple[str, str, bool]]] = {
    "sources.csv": [
        ("id", "text", True), ("title", "text", True), ("publisher", "text", True),
        ("year", "int", False), ("url", "text", False),
        ("type", "enum:SOURCE_TYPES", True), ("reliability", "int", False),
    ],
    "governorates.csv": [("id", "text", True), ("name_ar", "text", True), ("name_en", "text", True)],
    "wilayats.csv": [
        ("id", "text", True), ("governorate_id", "text", True),
        ("name_ar", "text", True), ("name_en", "text", True),
    ],
    "crops.csv": [
        ("id", "text", True), ("name_ar", "text", True), ("name_en", "text", True),
        ("scientific_name", "text", False), ("categories", "enums:CATEGORIES", True),
        ("lifecycle", "enum:LIFECYCLES", False), ("notes_ar", "text", False), ("notes_en", "text", False),
    ],
    "crop_requirements.csv": [
        ("crop_id", "text", True),
        ("t_min", "num", False), ("t_opt_low", "num", False), ("t_opt_high", "num", False), ("t_max", "num", False),
        ("chill_hours_min", "int", False), ("ece_threshold", "num", False), ("ece_slope", "num", False),
        ("ph_min", "num", False), ("ph_max", "num", False), ("textures", "enums:TEXTURES", False),
        ("alt_min", "int", False), ("alt_max", "int", False),
        ("season_days_min", "int", False), ("season_days_max", "int", False),
    ],
    "crop_stages.csv": [
        ("crop_id", "text", True), ("seq", "int", True), ("stage", "enum:STAGES", True),
        ("duration_days", "int", True), ("kc", "num", True),
    ],
}

FILES = ["sources.csv", "governorates.csv", "wilayats.csv", "crops.csv", "crop_requirements.csv", "crop_stages.csv"]

META_SPEC = [
    ("status", "enum:STATUSES", True), ("source_id", "text", True), ("source_page", "text", False),
    ("reviewed_by", "text", False), ("reviewed_at", "text", False),
]
for _f in FILES[1:]:
    COLUMNS[_f] = COLUMNS[_f] + META_SPEC

ENUMS = {
    "STATUSES": STATUSES, "CATEGORIES": CATEGORIES, "LIFECYCLES": LIFECYCLES,
    "SOURCE_TYPES": SOURCE_TYPES, "STAGES": STAGES, "TEXTURES": TEXTURES,
}
