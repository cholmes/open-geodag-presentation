#!/usr/bin/env bash
# =============================================================================
# Download Netherlands INSPIRE Buildings → GeoParquet
# =============================================================================
# Source:  Kadaster / PDOK – Gebouwen (INSPIRE geharmoniseerd)
# Derived from BAG (Basisregistratie Adressen en Gebouwen) + BRT
# INSPIRE theme: Buildings (BU), updated ~5x per year
#
# Requirements:
#   pip install --pre geoparquet-io
# =============================================================================

set -euo pipefail

# ---------- config ------------------------------------------------------------
WFS_URL="https://geodata.nationaalgeoregister.nl/inspire/bu/wfs"
OUTPUT_DIR="${HOME}/geodata/netherlands"
OUTPUT_FILE="${OUTPUT_DIR}/nl-inspire-buildings.parquet"
WORKERS=4          # parallel paged requests – good for large NL dataset
PAGE_SIZE=10000    # features per page
# -----------------------------------------------------------------------------

echo ""
echo "=== NL INSPIRE Buildings → GeoParquet ==="
echo "WFS: ${WFS_URL}"
echo "Output: ${OUTPUT_FILE}"
echo ""

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# ── Step 1: list available layers ────────────────────────────────────────────
echo "Listing available WFS layers..."
gpio extract wfs "${WFS_URL}"
echo ""

# ── Step 2: pick the right typename ──────────────────────────────────────────
# Expected typenames (INSPIRE BU core 2D profile):
#   bu-core2d:Building        ← main footprints (from BAG 'pand')
#   bu-core2d:BuildingPart    ← sub-parts if present
#
# If the layer list above shows different names, update TYPENAME below.
TYPENAME="bu-core2d:Building"

echo "Extracting typename: ${TYPENAME}"
echo "Using ${WORKERS} parallel workers, ${PAGE_SIZE} features/page"
echo ""

# ── Step 3: download WFS → GeoParquet ────────────────────────────────────────
gpio extract wfs \
  "${WFS_URL}" \
  "${TYPENAME}" \
  "${OUTPUT_FILE}" \
  --wfs-version 2.0.0 \
  --workers "${WORKERS}" \
  --page-size "${PAGE_SIZE}" \
  --compression zstd \
  --compression-level 15 \
  --output-crs EPSG:4326 \
  --overwrite \
  --verbose

echo ""

# ── Step 4: validate ─────────────────────────────────────────────────────────
echo "Validating output..."
gpio check all "${OUTPUT_FILE}"

echo ""

# ── Step 5: inspect ──────────────────────────────────────────────────────────
echo "Summary:"
gpio inspect "${OUTPUT_FILE}"

echo ""
echo "Done! File saved to: ${OUTPUT_FILE}"
echo ""
echo "If the typename above was wrong, re-run Step 3 with the correct name"
echo "from the layer listing printed in Step 1."
echo ""
echo "To also download BuildingParts:"
echo "  gpio extract wfs \\"
echo "    ${WFS_URL} \\"
echo "    bu-core2d:BuildingPart \\"
echo "    ${OUTPUT_DIR}/nl-inspire-buildingparts.parquet \\"
echo "    --wfs-version 2.0.0 --workers ${WORKERS} --page-size ${PAGE_SIZE} \\"
echo "    --compression zstd --compression-level 15 --output-crs EPSG:4326 --overwrite"
