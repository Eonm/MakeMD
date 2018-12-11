#!/usr/bin/env bash
for file in $(ls $MD_SRC*.md -A1); do
    pandoc $file -o $file
done
