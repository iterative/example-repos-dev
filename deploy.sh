#!/bin/bash

# e Exit immediately if a command exits with a non-zero exit status.
# u Treat unset variables as an error when substituting.
# v Print shell input lines as they are read.
# x Print commands and their arguments as they are executed.
set -euvx

PACKAGE_DIR=code
PACKAGE=code.zip
TEST_DIR=tmp
TEST_PACKAGE=$TEST_DIR/$PACKAGE

rm -f $PACKAGE
rm -rf $TEST_DIR
mkdir $TEST_DIR

pushd $PACKAGE_DIR
zip -r $PACKAGE src/* requirements.txt
popd

# Requires AWS CLI and write access to `dvc-share` S3 bucket.
mv $PACKAGE_DIR/$PACKAGE .
aws s3 cp --acl public-read $PACKAGE s3://dvc-share/get-started/$PACKAGE

# Testing
wget https://dvc.org/s3/get-started/$PACKAGE -O $TEST_PACKAGE
unzip $TEST_PACKAGE -d $TEST_DIR
cmp $PACKAGE $TEST_PACKAGE
rm -f $TEST_PACKAGE
diff -r $PACKAGE_DIR $TEST_DIR

