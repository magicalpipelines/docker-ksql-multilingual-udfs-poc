#!/usr/bin/env bash
set -euxo pipefail

INSTALL_DIR=/ksql-install
BUILD_DIR=/ksql

git clone -b feature-multilingual-udfs https://github.com/mitch-seymour/ksql.git $INSTALL_DIR

cd $INSTALL_DIR
time /maven/bin/mvn package -DskipTests | grep "Building.*[\d\+/\d\+\]\\|SUCCESS"

mkdir $BUILD_DIR &&  \
for project in ksql-engine ksql-rest-app ksql-cli; do
    for dir in "$project/target/$project"-*-development; do
      KSQL_DIR="$dir/share/java/$project"
      if [ -d "$KSQL_DIR" ]; then
        mkdir -p $BUILD_DIR/$KSQL_DIR && cp -R $KSQL_DIR/** $BUILD_DIR/$KSQL_DIR
      fi
    done
done

cp -R bin $BUILD_DIR/bin
cp -R config $BUILD_DIR/config

rm -rf $INSTALL_DIR
