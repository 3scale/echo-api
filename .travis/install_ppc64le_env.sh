#!/bin/bash

set -ev

bundle config --local set path 'vendor/bundle'
bundle lock --add-platform powerpc64le-linux

bundle check || bundle install --jobs=3 --retry=3
