#!/bin/sh

# e Exit immediately if a command exits with a non-zero exit status.
# u Treat unset variables as an error when substituting.
# x Print commands and their arguments as they are executed.
set -eux

PACKAGE_DIR=code
PACKAGE=code.zip
TEST_DIR=tmp
TEST_PACKAGE=$TEST_DIR/$PACKAGE

rm -f $PACKAGE
rm -rf $TEST_DIR
mkdir $TEST_DIR

pushd $PACKAGE_DIR
zip -r $PACKAGE src/*
popd

# Requires AWS CLI and write access to `s3://dvc-public/code/get-started/`.
mv $PACKAGE_DIR/$PACKAGE .
aws s3 cp --acl public-read $PACKAGE s3://dvc-public/code/get-started/$PACKAGE

# Sanity check
wget https://code.dvc.org/get-started/$PACKAGE -O $TEST_PACKAGE
unzip $TEST_PACKAGE -d $TEST_DIR

echo "\nNo output should be produced by the following cmp and diff commands:\n"

cmp $PACKAGE $TEST_PACKAGE  # Expected output: nothing
rm -f $TEST_PACKAGE
cp -f $PACKAGE_DIR/README.md $TEST_DIR
diff -r $PACKAGE_DIR $TEST_DIR  # Expected output: nothing
rm -fR $TEST_DIR
