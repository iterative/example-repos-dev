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

# Testing
wget https://code.dvc.org/get-started/$PACKAGE -O $TEST_PACKAGE
unzip $TEST_PACKAGE -d $TEST_DIR
# TODO: Print some info. on what to look for here.
cmp $PACKAGE $TEST_PACKAGE
rm -f $TEST_PACKAGE
diff -r $PACKAGE_DIR $TEST_DIR
