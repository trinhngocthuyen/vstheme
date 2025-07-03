#!/bin/sh
set -e

mkdir -p ~/Library/Developer/Xcode/UserData/FontAndColorThemes
python3 scripts/convert.py \
    -i xcode/chris-decor.xccolortheme.json \
    -o ~/Library/Developer/Xcode/UserData/FontAndColorThemes/chris-decor.xccolortheme
