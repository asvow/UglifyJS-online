#!/usr/bin/env bash

cd $(dirname "$0")
cd ..


# Get version from NPM
mkdir -p build/tmp/

NPM_JSON="build/tmp/npm-uglify-js.json"
curl --silent --show-error https://registry.npmjs.org/uglify-js > "$NPM_JSON"

VERSION=$(jq -r '."dist-tags".latest' "$NPM_JSON")
VERSION_GIT_HEAD=$(jq -r '.versions[."dist-tags".latest].gitHead' "$NPM_JSON")

rm -r build/tmp/

echo "Latest version is $VERSION ($VERSION_GIT_HEAD)"


# Update to this version
git clean -fd

git submodule update --init

cd uglify/

PREV_VERSION=$(jq -r '.version' package.json)

if [ "$VERSION" == "$PREV_VERSION" ]; then
	echo "Already on the latest version, no update needed"
	exit 0
fi

git fetch origin
if [ $? -ne 0 ]; then
    echo "Exiting, because it was not possible to fetch remote commits of this submodule"
    exit 1
fi

git pull --ff-only origin "$VERSION_GIT_HEAD"

if [ $? -ne 0 ]; then
    echo "Exiting, because it was not possible to pull this submodule version"
    exit 1
fi

cd ..


# Update default options
node build/update-options.js

if [ $? -ne 0 ]; then
    echo "Exiting, because updating options failed"
    exit 1
fi


# Run smoketest
node build/smoketest/smoketest.js

if [ $? -ne 0 ]; then
    echo "Exiting because of smoketest error"
    exit 1
fi


# Update version
if [[ `uname` == 'Darwin' ]]; then
    sed -i "" 's/\(<code id="version">\)[^<]*\(<\/code>\)/\1uglify-js '"$VERSION"'\2/' index.html
else
    sed -i 's/\(<code id="version">\)[^<]*\(<\/code>\)/\1uglify-js '"$VERSION"'\2/' index.html
fi


# Commit and push
git add index.html
git add uglify
git commit -m "Update to uglify-js $VERSION"
