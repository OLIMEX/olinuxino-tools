#!/bin/bash
VERSION=$(date +%Y%m%d-%H%M%S)

cat debian/changelog.template | sed "s/VERSION/${VERSION}/g" > debian/changelog
