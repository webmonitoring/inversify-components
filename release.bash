#!/bin/bash

# This script should be invoked through "npm run release"

git diff-index --quiet HEAD
if [[ $? -ne 0 ]] ; then
  echo "/!\\ You have local changes. Have you committed your changes first? If not, please run 'git stash --include-untracked' and retry."
  exit 1
fi

if [[ "$1" == "fast" ]] ; then
  echo "## FAST RELEASE MODE - USE WITH EXTREME CAUTION"
else
  echo "## NORMAL RELEASE MODE - FULL CLEAN AND REBUILD"
  make clean
fi

if [ `git rev-parse --abbrev-ref HEAD` != 'prod' ]
then
  echo "## THIS IS A Beta RELEASE, attempting build..."

  make build
  if [[ $? -ne 0 ]] ; then
      echo "## build failed! aborting release."
      exit 1
  fi

  export INCREMENTED_PACKAGE_VERSION=`npm version --no-git-tag-version prerelease --preid=beta | cut -c 2-`
  echo "## incremented package version: $INCREMENTED_PACKAGE_VERSION";

  git add package.json package-lock.json && git commit -m "Release beta version $INCREMENTED_PACKAGE_VERSION"
  if [[ $? -ne 0 ]] ; then
      echo "## git add failed! aborting release."
      exit 1
  fi
else
  echo "## THIS IS A PROD RELEASE, attempting build..."

  if [[ "$1" == "fast" ]] ; then
    make build
  else
    make build lint test
  fi
  if [[ $? -ne 0 ]] ; then
      echo "## build failed! aborting release."
      exit 1
  fi

  export INCREMENTED_PACKAGE_VERSION=`npm --no-git-tag-version version patch | cut -c 2-`
  echo "## incremented package version: $INCREMENTED_PACKAGE_VERSION";

  git add package.json package-lock.json && git commit -m "Release prod version $INCREMENTED_PACKAGE_VERSION" && git tag -a $INCREMENTED_PACKAGE_VERSION -m "Release version $INCREMENTED_PACKAGE_VERSION"
  if [[ $? -ne 0 ]] ; then
      echo "## git add failed! aborting release."
      exit 1
  fi
fi

git push --follow-tags
if [[ $? -ne 0 ]] ; then
    echo "## git push failed - not publishing!"
    exit 1
fi

cp package.json package-lock.json ./dist

npm publish ./dist --registry=https://npm.pkg.github.com
if [[ $? -ne 0 ]] ; then
    echo "## npm publish failed!"
    exit 1
fi
