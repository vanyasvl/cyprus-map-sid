#!/bin/bash
set -e

MKGMAP_DIR="/Users/sid/maps/mkgmap"
MAPNAME=41339000
MAP_FAMILY_ID=41339
MAP_DESCR="Cyprus OSM sid"
MAP_FAMILY_NAME="Cyprus OSM sid"
MAP_SERIES_NAME="Cyprus OSM sid"

CONTOUR_DIR="./contours"
CONTOUR_MAPNAME=41339000

# Dir with appropriate hgt files
SRTM_DIR="/Users/sid/maps/cyprus-srtm"

STYLE="maptourist-sid"

TYP_NAME="OSM-2018"

TMP_DIR="./tmp"
MAP_DIR="./map"
OUT_DIR="./output"

mkdir -p $TMP_DIR
mkdir -p $MAP_DIR
mkdir -p $OUT_DIR


# Clean old output files
rm -rf $OUT_DIR/*

# Download map
# wget http://download.geofabrik.de/europe/cyprus-latest.osm.pbf -O $TMP_DIR/cyprus.osm.pbf
# wget http://download.geofabrik.de/europe/cyprus.poly -O $TMP_DIR/cyprus.poly

# Build TYP file
java -cp $MKGMAP_DIR/mkgmap.jar uk.me.parabola.mkgmap.main.TypCompiler "$TYP_NAME.txt" "$OUT_DIR/$TYP_NAME.typ"

# Build map
java -Xmx1G -jar $MKGMAP_DIR/mkgmap.jar --verbose --output-dir=$OUT_DIR \
      --precomp-sea=$MKGMAP_DIR/sea.zip --bounds=$MKGMAP_DIR/bounds.zip \
      --mapname="$MAPNAME" --description="$MAP_DESCR" --family-name="$MAP_FAMILY_NAME" \
      --product-id=1 --family-id="$MAP_FAMILY_ID" --series-name="$MAP_SERIES_NAME" \
      --country-name=Cyprus --country-abbr=CY \
      --style-file=styles --style="$STYLE" \
      --gmapsupp --drive-on=left --gmapi \
      --name-tag-list=name:en,int_name,name \
      --code-page=1252 -c optionsfile.args \
      --dem-poly="$TMP_DIR/cyprus.poly" --dem="$SRTM_DIR" \
      --dem-dists=3312,13248,26512,53024 \
      "$OUT_DIR/$TYP_NAME.typ" \
      "$TMP_DIR/cyprus.osm.pbf"

cp -r $OUT_DIR/gmapsupp.img $OUT_DIR/*.gmap $MAP_DIR

# Buildeng contour lines
rm -rf $CONTOUR_DIR/*

cd $CONTOUR_DIR
phyghtmap --step=10 --line-cat=400,50 --pbf \
      --output-prefix=contour --source=srtm1 \
      --no-zero-contour \
      --srtm-version=3.0 "$SRTM_DIR"/*
cd -

java -Xmx1G -jar $MKGMAP_DIR/mkgmap.jar --verbose --output-dir=$CONTOUR_DIR \
      --country-name=Cyprus --country-abbr=CY \
      --max-jobs=3 --gmapsupp \
      --mapname=$CONTOUR_MAPNAME \
      --transparent --merge-lines --draw-priority=28 \
      --description="cyprus-contours" \
      --style-file=styles --style="$STYLE" \
      "$OUT_DIR/$TYP_NAME.typ" $CONTOUR_DIR/contour_*.pbf 

cp $CONTOUR_DIR/gmapsupp.img $MAP_DIR/gmapsupp-contours.img
