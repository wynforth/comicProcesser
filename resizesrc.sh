#!/bin/bash

#steps
#for each file
#	apply: convert "$file" -resize 512 -extent 512x512+0-132 "templateImage.tga" -compose copy-opacity -composite "templateFolder.tga" -compose dst-over -composite "folders/$file.tga"


#needed for osx
#sudo port install libicns

usage() {
	echo "Creates a 512x512 png based on included templates for use as a folder icon. Also creates ico files, and if libicns is installed icns files.	
	
$0 [opts] imgdir <outputdir>
	
	imgdir        The directory where your images are stored
	outputdir     Options, the location where the results end up. they will be put into their respective sub directories
	
OPTIONS:
	-P, --nopng   Will not retain the png file
	-W, --noico   Will not create an ico file
	-M, --noicns  Will not create an icns file
	-f, --force   Force overwriting of icons, otherwise it will only process new images
	-l, --label   Put a label on the folder tab
	-a, --all     Will create a 512x512 icon as part of the OSX icns file.
	-v, --verbose I hope we all know what this option does by now
			
IMAGES:
	These can be in (almost) any format and should be at least 512ps wide. It will work best with images that are at least a 3:2 ratio (512x341).
	
OUTPUT:
	The script creates a 512x512 png file with the template applied. it will also create an ico file with icons with dimensions 256, 48, 32,24, and 16. If possible it will also create an icns file with icons with dimensions 256, 128, 32, 16"
	
	if [[ -z "$icnsloc" ]]; then
		echo "Could not locate png2icns, libicns is probably not installed.
on OSX this can be installed through port (sudo port install libicns)
on Linux this can be installed through apttitude (sudo apt-get icnsutils)"
	fi	
	
}




#Setting up defaults
png=true
ico=true
icns=true
fullrange=false
icnsloc=$(which png2icns)
verbose=false
force=false
label=false
if [[ -z "$icnsloc" ]]; then icns=false; fi

while [ "$1" != "" ]; do
    case $1 in
		-a )				fullrange=true;;
		-P | --nopng )		png=false;;
		-W | --noico )		ico=false;;
        -M | --noicns )		icns=false;;
		-v | --verbose )    verbose=true;;
		-f | --force )		force=true;;
		-l | --label )		label=true;;
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
outbase=$(cd "$outbase"; pwd)


if $verbose; then
	echo "Dir: $dir";
	echo "Path: $path";
	echo "Out: $outbase";
fi


if [[ -d "$dir" ]]; then

	tmpdir="${path}/tmp"
	#files go in their respective folders
	outdir="${outbase}/resizejpg"
	
	cd "$dir";
	
	if [[ ! -d "$outdir" ]]; then 
		$(mkdir -p "$outdir")
	fi
	if $verbose; then echo "Storing png files in: $(pwd)/${outdir}"; fi

	if $force; then
		if $verbose; then
			echo "Forceing creation of files."
		fi
	fi
	
	#it needs this regardless
	

	echo "Processing Folder: $(pwd)"
	
	#exit;
	for file in *; do
		if [[ -s "$file" ]] && [[ ! -d "$file" ]]; then
			basename=$(basename "$file")
			filename=${basename%.*}
			
			
			
			if ! $force; then
				if [[ -s "$outdir/$filename.png" ]]; then
					echo "$basename already processed skipping."
					continue
				fi
			fi
			
			echo "Processing: $basename"
			
			#crweate the temp dir
			if [[ -d "$tmpdir" ]]; then $(rm -rf "$tmpdir"); fi
			$(mkdir -p "$tmpdir")
			
			#directory=$(dirname "$file")
			outfile="$tmpdir/${filename}.jpg"
					
			$(convert "$file" -resize 512 -crop 512x512+0+0 "$outfile")
			
			$(mv "$outfile" "${outdir}/${filename}.jpg")
			if $verbose; then echo "Saving ${filename}.png to $outdir"; fi
			
			#remove the tmp dir
			$(rm -rf "$tmpdir")
		fi
		
	done
else
	exit
fi