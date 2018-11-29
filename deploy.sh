#!/bin/bash

set -e
set -x

PACKAGE_DIR=code
PACKAGE=code.zip
TEST_DIR=tmp
TEST_PACKAGE=$TEST_DIR/$PACKAGE

rm -f $PACKAGE
rm -rf $TEST_DIR
mkdir $TEST_DIR

zip -r -j $PACKAGE $PACKAGE_DIR

aws s3 cp --acl public-read $PACKAGE s3://dvc-share/get-started/$PACKAGE

# Testing
wget https://dvc.org/s3/get-started/$PACKAGE -O $TEST_PACKAGE
unzip $TEST_PACKAGE -d $TEST_DIR
cmp $PACKAGE $TEST_$PACKAGE
rm -f $TEST_PACKAGE
diff -r $PACKAGE_DIR $TEST_DIR
