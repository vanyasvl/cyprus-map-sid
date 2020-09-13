#!/bin/bash
MKGMAP_DIR="/Users/sid/maps/mkgmap"
MAPNAME=41339000
MAP_DESCR="Cyprus OSM sid"
MAP_FAMILY_NAME="Cyprus OSM sid"

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

# Downloading map
wget http://download.geofabrik.de/europe/cyprus-latest.osm.pbf -O $TMP_DIR/cyprus.osm.pbf

# Build TYP file
java -cp $MKGMAP_DIR/mkgmap.jar uk.me.parabola.mkgmap.main.TypCompiler "$TYP_NAME.txt" "$OUT_DIR/$TYP_NAME.typ"

# Build map
java -Xmx1G -jar $MKGMAP_DIR/mkgmap.jar --verbose --output-dir=$OUT_DIR \
      --precomp-sea=$MKGMAP_DIR/sea.zip --bounds=$MKGMAP_DIR/bounds.zip \
      --mapname="$MAPNAME" --description="$MAP_DESCR" --family-name="$MAP_FAMILY_NAME" \
      --country-name=Cyprus --country-abbr=CY \
      --style-file=styles --style=$STYLE \
      --gmapsupp --drive-on=left --gmapi \
      --name-tag-list=name:en,int_name,name \
      --code-page=1252 -c optionsfile.args \
      "$OUT_DIR/$TYP_NAME.typ" \
      "$TMP_DIR/cyprus.osm.pbf"

cp -r $OUT_DIR/gmapsupp.img $OUT_DIR/*.gmap $MAP_DIR
