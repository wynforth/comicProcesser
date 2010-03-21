#! /bin/bash


# CHANGELOG
# v1.4
#	- 'infinite' depth to the folders each section between a - is made into a folder 
#	- depth level of folder structure defaults to 2
# v1.3 
# 	- added -#, --numbers toggle for determining whether issues numbers are preceded by a # or not (default assumes they are)
# 	- fixed a bug in single issue processing putting the tmp directory in the wrong place which could cause errors
# v1.2
# 	- implemented single issue processing
# 	
# TO DO
# - setting for how deep a folder structure to create default 2
# - test if the files is an arhive before processing it
# - option for not keeping a backup
# - option for automode (quiet, no backup, recursive)
# - option for superquiet mode (no output no logging)
# - option to turn off sorting
# - option to only sort
# - split sorting off to its own function
# - option for not setting the icon
# - specify your own regular expression for sorting
# - linux support
# - have it unset the executable bit of archive files
# - find alternatives to using external tools (mainly sips and seticon)
# 
# BUGS TO FIX








#requirement testing
quit=false
unrar=$(which unrar)
unzip=$(which unzip)
sips=$(which sips)
zip=$(which zip)
rar=$(which rar)
stat=$(which stat)
seticon=$(which seticon)
if [ -z "$seticon" ]; then
	echo "Could not locate seticon in $PATH. It is part of OSX Utils and found at http://www.sveinbjorn.org/osxutils_docs"
	echo "The script will continue however icons may not be properly created."
	seticon="/usr/local/bin/seticon"
fi
if [ -z "$sips" ]; then
	echo "Can not locate sips in $PATH."
	echo "The script will continue however icons may not be properly created."
fi
if [ -z "$unrar" ]; then
	echo "Can not locate unrar in $PATH. This can be installed through mac ports"
	quit=true
fi
if [ -z "$rar" ]; then
	echo "Can not locate rar in $PATH. This can be downloaded from rarlabs"
	quit=true
fi
if [ -z "$unzip" ]; then
	echo "Can not locate unzip in $PATH. This can be installed through mac ports"
	quit=true
fi
if [ -z "$zip" ]; then
	echo "Can not locate zip in $PATH. This can be installed through mac ports"
	quit=true
fi
if [ -z "$stat" ]; then
	echo "Can not locate stat in $PATH. This can be installed through mac ports"
	quit=true
fi
#quit if any of the required apps aren't found
if $quit; then
	echo "Install missing applications and try again."
	exit
fi



function processFile()
{
	file="$1"
	echo "${tab}processing $file"
	#return
	
	#tmpfolder="${basedir}Unread/Sort/Work" #temp dir used for processing in
	#just make a local tmp dir to use
	tmpfolder="tmp"
	if [ -d "$tmpfolder" ]; then
		`rm -rf "$tmpfolder"`
	fi
	$(mkdir "$tmpfolder")

	#echo $tmpfolder
	
	basename=$(basename "$file") #filename
	
	folname="${tmpfolder}/${basename%.*}" #folder from file without extension

	`cp "$file" "${backup}"`

	#used for sorting 
	noext=${basename%.*}
	if $pound; then
		unnumbered=${noext%% \#*}
	else
		unnumbered=${noext%% [#0-9]**}
	fi
	
	#loop through $unnumbered splitting on ' - '
	sortdir="${basedir}/"
	cur=0
	for i in $(echo "$unnumbered")
	do
		echo "$cur"
		if [[ "$cur" -le "$depth" ]] || [[ "$depth" == "0" ]]; then
			cur=$(expr $cur + 1)
			sortdir="${sortdir}"
			if [[ "$i" == "-" ]]; then
				sortdir="${sortdir}/"
			else
				if [[ "$sortdir" != */ ]]; then
					sortdir="${sortdir} $i"
				else
					sortdir="${sortdir}$i"
				fi	
			fi
		fi
	done
	sortdir="${sortdir}/"
	echo "$sortdir"

	if [ ! -d "$sortdir" ]; then
		#echo "dir $sortdir doesnt' exists"
		`mkdir -p "$sortdir"`
	fi

    rarname="${folname}.cbr"
    zipname="${folname}.cbz"

	#finished file
	finfile="${sortdir}${basename}"

	#attempt to unrar
	`$unrar e -ad -id[c,q,p,d] "$file" "$tmpfolder" >> /dev/null`

	#if rar didn't work
	if [ ! -d "$folname" ]; then
		`$unzip -jq "$file" -d "$folname"`
	fi
	#if the folder still isn't there exit
	if [ ! -d "$folname" ]; then
		exit 1
	fi
	
	if $interactive; then 
		`open "${folname}"`
		read -p "Skip processing of this file? y/[n] : " skip
		if [[ "$skip" == "Y" ]] || [[ "$skip" == "y" ]]; then
			`rm -rf "$tmpfolder"`
			return
		fi
	fi
	

	#backup current to tempname, create a rar and zip file of it
     		#`cp "$file" "$tempname"`

    `$zip -jqr9x*.DS_Store "${zipname}" "${folname}"` 
    `$rar a -ep -m5 -x*.DS_Store -id[c,q,p,d] "${rarname}" "${folname}"`

	#get file sizes
	origsize=$($stat -f %z "$file")
	zipsize=$($stat -f %z "$zipname")
	rarsize=$($stat -f %z "$rarname")

	#echo $origsize
	if [ $zipsize -ge $rarsize ]; then
		final=$rarname
		finalsize=$rarsize
		`rm "$zipname"`
	else
		final=$zipname
		finalsize=$zipsize
		`rm "$rarname"`
	fi

	if [ $origsize -le $finalsize ]; then
		`rm "$final"`
		#mv "$file" "${tmpfolder}/"`
		final=$file
		if $verbose; then 
			echo "Using original file"
		fi
	else
		$(rm "$file")
	fi
	
	if $verbose; then
		size=$(expr $origsize - $finalsize)
		saved=$(echo "scale=2;$size / 1048576" | bc -l)
		echo "${basename} - Saved $saved Mb"
	fi

	#set icon
	image=`ls "$folname" | grep  -m1 -i -e "jpg\|gif\|png"`
	`$sips -i "$folname/$image" >> /dev/null`
	`$seticon "$folname/$image" "$final"`

	#get series and item name
	#test and ake dirs as needed

	if $verbose; then echo "Moving ${final} to ${finfile}"; fi
	$(mv "$final" "$finfile")
	
	$(rm -rf "$folname")
	$(rm -rf "$tmpfolder")
}

function processDir()
{
	cd "$1"
	tab="$tab  "
	for file in *; do
		if [ -d "$file" ]; then
			
			if $recurse; then 
				if $interactive; then
					read -p "Process folder $file? [y]/n : " skip
					if [[ "$skip" == "n" ]] || [[ "$skip" == "N" ]]; then
						continue;
					fi
				fi
				if $verbose; then echo "${tab}Processing: $file as directory"; fi
				processDir "$file"
			fi
		elif [ -s "$file" ]; then
			processFile "$file"
		fi
	done
	cd ".."
	tab="${tab%  }"
}

function usage
{
	
echo "usage: $0 [-opts] <item>

Processes comics so that it adds an icon to match (usually) the cover, but uses whatever the first image is.
Recompresses the files into both cbr, and cbz keeps the file with the smallest size
Sorts them into their respective folders based on:
Man Directory - <sub folder> - <extra stuff> #000.ext
Example:
file: X-Men - Legacy #465.cbz
would go to /X-Men/Legacy/X-Men - Legacy #465.cbz

if item is a directory will process all files in the directory, and sub directories
if item is a file will only process that single file


OPTIONS:
   -h, --help           Show this message
   -d <path>, --topdir  Top path to where your comics are stored [Default: ~/Comics]
   -b <path>, --backup  Path to backup original file to. [Default: ~/Comics/Backup]
   --level, -l #        Depth level of folder structure created, use 0 for infinite. [Default: 2]
   --numbers, -n        Don't use # in parsing just use the last number in the filename                
   --nonrecursive, -N   Does not recurse into subdirectories. This option is ignored if <item> is a file
   --interactive, -i    Interactive mode, will open folders and give you a pause to modify the files
   --verbose, -v        Verbose
   --quiet, -q          Output is redirected a log file: $(basename ${0%.*}).log. Can not be used with interactive mode

INTERACTIVE MODE:
	Using the -i or --interactive option this script will operate in interactive mode. After extracting a file the script will open the extracted directory and pause. At this time you can add/remove/edit files. Once you are done simply return to the script and press enter to continue. You will also be presented with the option to stop the script after each directory.
"
}

function folderState
{
	echo "Backup Directory: $backup"
	echo "Base Directory:   $basedir"
	recursiveState
	interactiveState
}
function recursiveState
{
	if $recurse; then
		echo "Recursing subdirectories"
	else
		echo "Not recursing subdirectories"
	fi
}
function interactiveState
{
	if $interactive; then
		echo "interactive mode is on"
	else
		echo "interactive mode is off"
	fi
}

###########################
#                         #
#   OPTION PROCESSING     #
#                         #
###########################
#defaults
basedir=`find ~/Comics`
backup="$(find ~/Comics)/Backups"
recurse=true
interactive=false
quiet=false
verbose=false
pound=true
logfile="$(basename ${0%.*}).log"
depth=2

while [ "$1" != "" ]; do
    case $1 in
		-d )					shift
								basedir=$1
								;;
		-b )					shift
								backup=$1
								;;
		-N | --nonrecursive )	recurse=false;;
		-v | --verbose )		verbose=true;;
		-q | --quiet )			quiet=true;;
        -i | --interactive )    interactive=true;;
		-n | --numbers )        pound=false;;
        -h | --help )           usage
                                exit
                                ;;
		-l | --level )			shift
								depth=$1
								;;
        * )						if [ -z "$2" ]; then
									item="$1"
								else
									usage
                                	exit 1
								fi
    esac
    shift
done

if [[ -z "$item" ]]; then
	usage
	exit 1
fi

#interactive and quiet can't easily work together, give precedence to interactive
if $interactive; then quiet=false; fi
#if it's being quiet redirect stdout to a log file
if $quiet; then	exec 1>$logfile; fi

#convert relative path to absolute path for output
if [[ ! "$backup" = /* ]]; then
	backup="$(pwd)/$backup"
fi

#remove trailing slash on directories
backup=${backup%/}
basedir=${basedir%/}

if [[ ! -d "$backup" ]]; then
	if $verbose; then echo "Attempting to create backup directory: $backup"; fi
	result=$(mkdir -p "$backup" 2>&1)
	if [[ ! -d "$backup" ]]; then
		if $verbose; then echo "$result"; fi
		echo "Couldn't create backup directory. Script stopping to prevent dataloss"
		exit 1
	fi
fi

if [[ -d "$item" ]]; then
	if $verbose; then folderState; fi
	echo "Processing: \"$item\" as a directory"
	processDir "$item"
elif [[ -s "$item" ]]; then
	nonrecursive=1
 	if [[ "$verbose" == 1 ]]; then folderState; fi
	curdir="$(pwd)"
	cd "$(dirname "$item")"
	processFile "$item"
else
	echo "Could not process \"$item\" make sure the name is entered correctly."
fi

if $quiet; then	exec 1>&-; fi