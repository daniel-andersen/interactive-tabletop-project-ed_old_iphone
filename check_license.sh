#!/bin/bash
find . -type f -name "**.m" -not -path "*opencv2.framework*" | xargs -I{} grep -L "Copyright (c) 2014, Daniel Andersen (daniel@trollsahead.dk)" "{}"
find . -type f -name "**.mm" -not -path "*opencv2.framework*" | xargs -I{} grep -L "Copyright (c) 2014, Daniel Andersen (daniel@trollsahead.dk)" "{}"
find . -type f -name "**.h" -not -path "*opencv2.framework*" | xargs -I{} grep -L "Copyright (c) 2014, Daniel Andersen (daniel@trollsahead.dk)" "{}"

