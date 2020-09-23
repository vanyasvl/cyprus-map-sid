#!/bin/bash
set -e

MKGMAP_DIR="/Users/sid/maps/mkgmap"
MAPNAME=41339000
MAP_FAMILY_ID=41339
MAP_DESCR="Cyprus OSM sid"
MAP_FAMILY_NAME="Cyprus OSM sid"
MAP_SERIES_NAME="Cyprus OSM sid"
STYLE="maptourist-sid"
TYP_FILE="OSM-2018.txt"

TMP_DIR="./tmp"
MAP_DIR="./map"
OUT_DIR="./output"

SRTM_URL="http://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL1.003/2000.02.11"
CYPRUS_MAP_URL="http://download.geofabrik.de/europe/cyprus-latest.osm.pbf"

mkdir -p "$TMP_DIR" "$OUT_DIR" "$MAP_DIR"

echo Cleaning old output files
rm -rf "$OUT_DIR"/*
echo Cleaning old temp files
rm -rf "$TMP_DIR"/*

echo Downloading Cyprus map
wget -q --show-progress "$CYPRUS_MAP_URL" -O "$TMP_DIR/cyprus.osm.pbf"

echo Downloading srtm files
wget -q --show-progress --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N34E032.SRTMGL1.hgt.zip" -O "$TMP_DIR/N34E032.SRTMGL1.hgt.zip"
wget -q --show-progress --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N34E033.SRTMGL1.hgt.zip" -O "$TMP_DIR/N34E033.SRTMGL1.hgt.zip"
wget -q --show-progress --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N34E034.SRTMGL1.hgt.zip" -O "$TMP_DIR/N34E034.SRTMGL1.hgt.zip"
wget -q --show-progress --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N35E032.SRTMGL1.hgt.zip" -O "$TMP_DIR/N35E032.SRTMGL1.hgt.zip"
wget -q --show-progress --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N35E033.SRTMGL1.hgt.zip" -O "$TMP_DIR/N35E033.SRTMGL1.hgt.zip"
wget -q --show-progress --user "$USGS_USER" --password "$USGS_PASSWORD" "$SRTM_URL/N35E034.SRTMGL1.hgt.zip" -O "$TMP_DIR/N35E034.SRTMGL1.hgt.zip"

echo Unpacking srtm files
unzip -q -o "$TMP_DIR"/\*.zip -d "$TMP_DIR"

echo Building contour lines
cd "$TMP_DIR"
phyghtmap --step=10 --line-cat=400,50 --pbf \
      --output-prefix=contour \
      --no-zero-contour \
      --srtm-version=3.0 *.hgt
cd -

echo Merging contour maps
osmium merge "$TMP_DIR"/contour_*.pbf -o "$TMP_DIR/contours.pbf"
echo Cutting contour map
osmium extract --polygon cyprus.poly "$TMP_DIR/contours.pbf" -o "$TMP_DIR/cyprus_contours.pbf"

echo Building map
java -Xmx1G -jar "$MKGMAP_DIR/mkgmap.jar" --verbose --output-dir="$OUT_DIR" \
      --precomp-sea="$MKGMAP_DIR/sea.zip" --bounds="$MKGMAP_DIR/bounds.zip" \
      --mapname="$MAPNAME" --description="$MAP_DESCR" --family-name="$MAP_FAMILY_NAME" \
      --product-id=1 --family-id="$MAP_FAMILY_ID" --series-name="$MAP_SERIES_NAME" \
      --country-name=Cyprus --country-abbr=CY \
      --style-file=styles --style="$STYLE" \
      --style-option=code-page=1250 \
      --gmapsupp --drive-on=left --gmapi \
      --name-tag-list=name:en,int_name,name \
      --latin1 -c optionsfile.args \
      --dem="$TMP_DIR" --dem-poly=cyprus.poly \
      --dem-dists=3312,13248,26512,53024 \
      "$TMP_DIR/cyprus.osm.pbf" "$TYP_FILE" \
      --transparent --merge-lines --draw-priority=28 \
      "$TMP_DIR/cyprus_contours.pbf"

cp -r "$OUT_DIR/gmapsupp.img" "$OUT_DIR"/*.gmap "$MAP_DIR"

echo All done
