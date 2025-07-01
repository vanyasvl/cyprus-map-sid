#!/bin/bash
set -e

MAPNAME=41339000
MAP_FAMILY_ID=41339
MAP_DESCR="Cyprus OSM sid"
MAP_FAMILY_NAME="Cyprus OSM sid"
MAP_SERIES_NAME="Cyprus OSM sid"
STYLE="maptourist-sid"
TYP_FILE="typ-sid.txt"

MKGMAP_DIR="${MKGMAP_DIR:-/tmp/mkgmap}"
SPLITTER_DIR="${SPLITTER_DIR:-/tmp/splitted_map}"

SRTM_URL="https://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL1.003/2000.02.11"
CYPRUS_MAP_URL="https://download.geofabrik.de/europe/cyprus-latest.osm.pbf"

mkdir -p tmp output srtm_downloads

echo Downloading Cyprus map
wget -nv -q "$CYPRUS_MAP_URL" -O "tmp/cyprus.osm.pbf"

echo Downloading srtm files
wget -nv -q -c --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N34E032.SRTMGL1.hgt.zip" -O "srtm_downloads/N34E032.SRTMGL1.hgt.zip"
wget -nv -q -c --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N34E033.SRTMGL1.hgt.zip" -O "srtm_downloads/N34E033.SRTMGL1.hgt.zip"
wget -nv -q -c --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N34E034.SRTMGL1.hgt.zip" -O "srtm_downloads/N34E034.SRTMGL1.hgt.zip"
wget -nv -q -c --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N35E032.SRTMGL1.hgt.zip" -O "srtm_downloads/N35E032.SRTMGL1.hgt.zip"
wget -nv -q -c --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N35E033.SRTMGL1.hgt.zip" -O "srtm_downloads/N35E033.SRTMGL1.hgt.zip"
wget -nv -q -c --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N35E034.SRTMGL1.hgt.zip" -O "srtm_downloads/N35E034.SRTMGL1.hgt.zip"

echo Unpacking srtm files
unzip -q -o "srtm_downloads/*.zip" -d "./tmp"

echo Building contour lines
cd ./tmp
phyghtmap --step=20 --line-cat=400,50 --pbf \
      --output-prefix=contour \
      --no-zero-contour \
      --srtm-version=3.0 ./*.hgt
cd -

echo Merging contour maps
osmium merge --overwrite ./tmp/contour_*.pbf -o ./tmp/contours.pbf
echo Cutting contour map
osmium extract --overwrite --polygon cyprus.poly ./tmp/contours.pbf -o ./tmp/cyprus_contours.pbf


echo Split Map
java -Xmx16G \
      -jar "${SPLITTER_DIR}/splitter.jar" \
      --max-nodes=1600000 \
      --overlap=0 \
      --output-dir=tmp/splitted \
      --output=pbf \
      --keep-complete=true \
      --no-trim \
      ./tmp/cyprus.osm.pbf

echo Split Contours
java -Xmx16G \
      -jar "${SPLITTER_DIR}/splitter.jar" \
      --max-nodes=1600000 \
      --overlap=0 \
      --output-dir=tmp/splitted_contours \
      --output=pbf \
      --keep-complete=true \
      --no-trim \
      ./tmp/cyprus_contours.pbf

echo Building map
java -Xmx3G -jar "${MKGMAP_DIR}/mkgmap.jar" --verbose --max-jobs=2 --output-dir="./output" \
      --precomp-sea="${MKGMAP_DIR}/sea-latest.zip" --bounds="${MKGMAP_DIR}/bounds-latest.zip" \
      --mapname="$MAPNAME" --description="$MAP_DESCR" --family-name="$MAP_FAMILY_NAME" \
      --product-id=1 --family-id="$MAP_FAMILY_ID" --series-name="$MAP_SERIES_NAME" \
      --country-name=Cyprus --country-abbr=CY \
      --style-file=styles --style="$STYLE" \
      -c optionsfile.args \
      --drive-on=left \
      --dem="./tmp" --dem-poly=cyprus.poly \
      --dem-dists=3312,13248,26512,53024 \
      -c tmp/splitted/template.args "$TYP_FILE" \
      --transparent --merge-lines --draw-priority=28 \
      -c tmp/splitted_contours/template.args

echo Compressing maps
cd ./output
zip -r "Cyprus_OSM.gmap.zip" "Cyprus OSM sid.gmap"
zip -r "gmapsupp.img.zip" "gmapsupp.img"
cd -

echo "Build is finished"
