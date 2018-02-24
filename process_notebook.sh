#!/bin/bash

FILE=$1
FILENAME="${FILE%%.*}"
FILE_DIR="${FILENAME}_files"

if [ -d $FILE_DIR ]; then
	# When converting a notebook to markdown, all the images in the markdown file link to the files
	# folder created when converting. We need to replace the file folder with
	# the static images folder used by Pelican.
	sed -i "" "s/${FILE_DIR}/images/g" $1

	# Also copy images from file directory to images
  cp $FILE_DIR/* images
	rm -r $FILE_DIR
fi
