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


if [[ -d "$dir" ]]; then

	tmpdir="${path}/tmp"
	#files go in their respective folders
	outdir="${outbase}/png"
	outico="${outbase}/ico"
	outicns="${outbase}/icns"
	

	cd "$dir"
	if $ico; then 
		if [[ ! -d "$outico" ]]; then 
			$(mkdir -p "$outico")
		fi
		if $verbose; then echo "Storing ico files in: $(pwd)/${outico}"; fi
	fi
	if $icns; then 
		if [[ ! -d "$outicns" ]]; then 
			$(mkdir -p "$outicns")
		fi
		if $verbose; then echo "Storing icns files in: $(pwd)/${outicns}"; fi
	fi
	if $png; then 
		if [[ ! -d "$outdir" ]]; then 
			$(mkdir -p "$outdir")
		fi
		if $verbose; then echo "Storing png files in: $(pwd)/${outdir}"; fi
	fi

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
			filename=${basename%.*}
			
			
			
			if ! $force; then
				if [[ -s "$outicns/$filename.icns" ]] && [[ -s "$outico/$filename.ico" ]] && [[ -s "$outdir/$filename.png" ]]; then
					echo "$basename already processed skipping."
					continue
				fi
			fi
			
			echo "Processing: $basename"
			
			#crweate the temp dir
			if [[ -d "$tmpdir" ]]; then $(rm -rf "$tmpdir"); fi
			$(mkdir -p "$tmpdir")
			
			#directory=$(dirname "$file")
			outfile="$tmpdir/${filename}.png"
					
			$(convert "$file" -resize 512 -extent 512x512+0-132 "$path/templateImage.tga" -compose copy-opacity -composite "$path/templateFolder.tga" -compose dst-over -composite "$outfile")
			
			#label
			if $label; then
				name="${filename##* - }"
				name="${name% \(*}"
				#echo "$name"
				tmptxt="$tmpdir/tmptext.png"
				$(convert -size 154x30 -background transparent -fill "#CCCCCC" -font Impact -gravity south label:"$name" "$tmptxt")
				$(convert "$outfile" "$tmptxt" -gravity center -geometry -122-160 -compose screen -composite "$outfile")  
				
			fi
			
		
			#tmp dir for making the small images needed for icons
			if $ico | $icns; then
				if $verbose; then echo "creating files for ico"; fi
					
				#remove previous tmp dir and create a new one to use
				if [[ -d "$tmpdir/tmp" ]]; then $(rm -rf "$tmpdir/tmp"); fi
				$(mkdir -p "$tmpdir/tmp")

				#makes a .ico file that should be usable on windows and linux
				#icos should be 256, 48, 32, 24, 16
				if $ico; then
					sizes=("256" "48" "32" "24" "16")
					toEval="convert"
					for i in ${sizes[@]}; do
						$(convert "$outfile" -resize $i "$tmpdir/tmp/tmp_$i.png")
						toEval="$toEval \"$tmpdir/tmp/tmp_$i.png\""
					done
					#echo "convert$toEval \"$outico/$filename.ico\""
					$(eval "$toEval \"$outico/$filename.ico\"")
				fi
			
				if $icns; then
					#icns should be *512, 256, 128, 32, 16	
					if $verbose; then echo "creating files for icns"; fi	
					if $fullrange; then
						sizes=("512" "256" "128" "32" "16")
					else
						sizes=("256" "128" "32" "16") #512 isn't really useful and wastes space
					fi
					toEval="png2icns \"$outicns/$filename.icns\""
					for i in ${sizes[@]}; do
						f="$tmpdir/tmp/tmp_$i.png"
						if [[ ! -s "$f" ]]; then
							$(convert "$outfile" -resize $i "$tmpdir/tmp/tmp_$i.png")
					
						fi
						toEval="$toEval \"$tmpdir/tmp/tmp_$i.png\""
					done
					#echo "$toEval"
					$(eval "$toEval >> /dev/null")
				fi
				
				#remove tmp dir
				$(rm -rf "$tmpdir/tmp")
			fi
			
			#only move over the file if we are suposed to retain it
			if $png; then
				$(mv "$outfile" "${outdir}/${filename}.png")
				if $verbose; then echo "Saving ${filename}.png to $(pwd)/$outdir"; fi
			fi
			
			#remove the tmp dir
			$(rm -rf "$tmpdir")
		fi
		
	done
else
	exit
fi