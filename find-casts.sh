#!/bin/sh
# Lists the lines of C# in the current git repository that may convert a double or float to decimal.
git grep -nE \
  -e '\((System\.)?[Dd]ecimal\??\)' \
  -e 'ToDecimal' \
  -e 'new (System\.)?[Dd]ecimal\(' \
  -e '[Dd]ecimal\.Create(Checked|Saturating|Truncating)' \
  -- '*.cs'
