#!/bin/bash

#steps
#for each file
#	apply: convert "$file" -resize 512 -extent 512x512+0-132 "templateImage.tga" -compose copy-opacity -composite "templateFolder.tga" -compose dst-over -composite "folders/$file.tga"


#needed for osx
#sudo port install libicns

usage() {
	echo "Creates a 640x480 png based on included templates for use as a folder background.
	
$0 [opts] imgdir <outputdir>
	
	imgdir        The directory where your images are stored
	outputdir     Options, the location where the results end up. they will be put into their respective sub directories
	
OPTIONS:
	-f, --force   Force overwriting of icons, otherwise it will only process new images
	--png 		  create pngs instead of jpgs, if you want to preserve transperency but not sure it matters
	-v, --verbose I hope we all know what this option does by now
			
IMAGES:
	These can be in (almost) any format and should be at least 640px wide or 480 tall. It will work best with images that are at least a 4:3 ratio.
	
OUTPUT:
	The script creates a 640x480 png file with the template applied."
		
}




#Setting up defaults
verbose=false
force=false
png=false
while [ "$1" != "" ]; do
    case $1 in
		-v | --verbose )    verbose=true;;
		-f | --force )		force=true;;
		--png )				png=true;;
        * )					if [ -z "$3" ]; then
								dir="$1"
								shift
								outbase="$1"
							else
								usage
                               	exit 1
							fi
    esac
    shift
done

if [[ -z "$dir" ]]; then
	usage
	exit 1
fi

#script directory
path=$(pwd)

if [[ "$outbase" != */ ]] && [[ -n "$outbase" ]]; then
	outbase="${outbase}/"
fi
#get the absolute path
outbase=$(cd "$outbase"; pwd)

if [[ -d "$dir" ]]; then

	tmpdir="${path}/tmp"
	outdir="${outbase}/bg"

	cd "$dir"
	if [[ ! -d "$outdir" ]]; then 
		$(mkdir -p "$outdir")
	fi
	if $verbose; then echo "Storing backgrounds in: $(pwd)/${outdir}"; fi

	if $force; then
		if $verbose; then
			echo "Forceing creation of files."
		fi
	fi
	
	#it needs this regardless
	echo "Processing Folder: $(pwd)"
	
	for file in *; do
		if [[ -s "$file" ]] && [[ ! -d "$file" ]]; then
			basename=$(basename "$file")
			if $png; then
				outfile="${outdir}/${basename%.*}.png"
			else
				outfile="${outdir}/${basename%.*}.jpg"
			fi

			
			
			if ! $force; then
				if [[ -s "$outfile" ]]; then
					echo "$basename already processed skipping."
					continue
				fi
			fi
			
			echo "Processing: $basename"
			
			#crweate the temp dir
			if [[ -d "$tmpdir" ]]; then $(rm -rf "$tmpdir"); fi
			$(mkdir -p "$tmpdir")
								
			$(convert "$file" -resize '640x480^' -extent 640x480 "$path/templateBackground.tga" -compose copy-opacity -composite "$path/templateWhite.png" -compose dst-over -composite "$outfile")
					
			#$(mv "$outfile" )
			if $verbose; then echo "Saving ${filename}.png to $(pwd)/$outdir"; fi
			#remove the tmp dir
			$(rm -rf "$tmpdir")
		fi
	done
else
	exit
fi