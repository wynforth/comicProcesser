#! /bin/bash

#echo "$SHELL"
#determine OS version, needed for some checks

os=$(uname)
case $os in
	Darwin ) platform="OSX";;
	Linux ) platform="Linux";;
esac

#echo "$platform"

#requirement testing
quit=false
unrar=$(which unrar)
unzip=$(which unzip)
sips=$(which sips)
zip=$(which zip)
rar=$(which rar)
stat=$(which stat)
seticon=$(which seticon)
if [ "$platform" = "OSX" ]; then
	if [ -z "$seticon" ]; then
		echo "Could not locate seticon in $PATH. It is part of OSX Utils and found at http://www.sveinbjorn.org/osxutils_docs"
		echo "The script will continue however icons may not be properly created."
		seticon="/usr/local/bin/seticon"
	fi
	if [ -z "$sips" ]; then
		echo "Can not locate sips in $PATH."
		echo "The script will continue however icons may not be properly created."
	fi
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

sortFile()
{
	file=$1
	basename=$(basename "$file") #filename
	
	#used for sorting 
	noext=${basename%.*}
	if $pound; then
		unnumbered=${noext%% \#*}
	else
		unnumbered=${noext%% [#0-9]**}
	fi
	
	#if there is no number it should drop directly level by one. unless that woudl reduce the depth to none
	
	sortdir=""
	cur=0
	
	#loop through $unnumbered splitting on ' - '
	for i in $(echo "$unnumbered")
	do
		if [ "$cur" -lt "$depth" ] || [ "$depth" == "0" ]; then
			
			sortdir="${sortdir}"
			if [ "$i" == "-" ]; then
				cur=$(expr $cur + 1)
				sortdir="${sortdir}/"
			else
				if [[ "$sortdir" != */ ]] && [[ -n "$sortdir" ]]; then
					sortdir="${sortdir} $i"
				else
					sortdir="${sortdir}$i"
				fi	
			fi
		fi
		#special sorting for dated directories of a single depth
		#this is to keep the files into their series folder without needing extra file names
		#X-Men (2005).cbz vs X-Men - X-Men (2005).cbz
		if [[ "$cur" -eq "0" ]] && [[ "$sortdir" = *\(* ]]; then
			sortdir="${sortdir% \(*}/$sortdir"
		fi
	done
	
	
	#special sorting for unnumbered files
	if [[ "$noext" = "$unnumbered" ]]; then
		#remove the last entry if there is no number
		shortdir="${sortdir%/*}"
		#echo "$sortdir - $shortdir"
		if [[ -n "$shortdir" ]]; then
			sortdir="$shortdir"
		fi
	fi
	

	
	
	
	sortdir="${basedir}/${sortdir}"
	if [[ "$sortdir" != */ ]]; then sortdir="${sortdir}/"; fi
		
	#echo "$sortdir"
	
	#create the directory
	if [ ! -d "$sortdir" ]; then `mkdir -p "$sortdir"`; fi
	final="${sortdir}${basename}"
	
	$(mv "$file" "$final")
	
	if $verbose; then
		echo "Sorted location: $final"
	fi	
}

processFile()
{
	file="$1"
	
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

	final=$file
	
	echo "${tab}processing $file"

    rarname="${folname}.cbr"
    zipname="${folname}.cbz"

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

	if [ "$platform" = "OSX" ]; then
		origsize=$($stat -f %z "$file")
	elif [ "$platform" = "Linux" ]; then
		origsize=$($stat -c %s "$file")
	fi

	if $interactive && [[ "$origsize" -gt "$isize" ]]; then 
		`open "${folname}"`
		read -p "Skip processing of this file? y/[n] : " skip
		if [ "$skip" == "Y" ] || [ "$skip" == "y" ]; then
			`rm -rf "$tmpfolder"`
			return
		fi
	fi
	
	#backup current to tempname, create a rar and zip file of it
     		#`cp "$file" "$tempname"`

    `$zip -jqr9x*.DS_Store "${zipname}" "${folname}"` 
    `$rar a -ep -m5 -x*.DS_Store -id[c,q,p,d] "${rarname}" "${folname}"`

	#get file sizes
	if [ "$platform" = "OSX" ]; then
		zipsize=$($stat -f %z "$zipname")
		rarsize=$($stat -f %z "$rarname")
	elif [ "$platform" = "Linux" ]; then
		zipsize=$($stat -c %s "$zipname")
		rarsize=$($stat -c %s "$rarname")
	fi
	
	
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

	#set icon only needed for osx
	if [ "$platform" = "OSX" ]; then
		image=$(ls "$folname" | grep  -m1 -i -e "jpg\|gif\|png\|bmp")
		eval "sips -i \"$folname/$image\" >> /dev/null"
		`$seticon "$folname/$image" "$final"`
	fi


	#get series and item name
	#test and ake dirs as needed



	if $sort; then
		sortFile "$final"
	else
		#otherwise just keeps it's location the same
		$(mv "$final" "$file")
	fi
	
	
	
	#$(rm -rf "$folname")
	$(rm -rf "$tmpfolder")
}


processDir()
{
	cd "$1"
	tab="$tab  "
	for file in *; do
		if [ -d "$file" ]; then
			if [ "$file" != "Backups" ]; then
				if $recurse; then 
					if $interactive && [[ "$isize" -ne "0" ]]; then
						read -p "Process folder $file? [y]/n : " skip
						if [ "$skip" == "n" ] || [ "$skip" == "N" ]; then
							continue;
						fi
					fi
					if $verbose; then echo "${tab}Processing: $file as directory"; fi
					processDir "$file"
				fi
			fi
		elif [ -s "$file" ]; then
			#backup file
			if $makebackup; then `cp "$file" "${backup}"`; fi
			#process file
			if $process; then 
				processFile "$file"
			elif $sort; then #processing includes sorting so only run this if the file wasn't processed
				sortFile "$file"
			fi
		fi
	done
	cd ".."
	tab="${tab%  }"
}

usage()
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
   --nosort, -S         Don't sort the file
   --sortonly, -s       Only sort don't worry about processing, or setting an icon. still makes a backup.
   --nobackup, -B       Don't create a backup, be careful
   --noprocess, -P      Don't process the files only sort them.
   --numbers, -n        Don't use # in parsing just use the last number in the filename                
   --nonrecursive, -N   Does not recurse into subdirectories. This option is ignored if <item> is a file
   --interactive, -i    Interactive mode, will open folders and give you a pause to modify the files
   -li #                Limited interactive, likr interactive mode but only on files larger then specified in MB 
   --verbose, -v        Verbose
   --quiet, -q          Output is redirected a log file: $(basename ${0%.*}).log. Can not be used with interactive mode

INTERACTIVE MODE:
	Using the -i or --interactive option this script will operate in interactive mode. After extracting a file the script will open the extracted directory and pause. At this time you can add/remove/edit files. Once you are done simply return to the script and press enter to continue. You will also be presented with the option to stop the script after each directory.
"
}

folderState()
{
	echo "Backup Directory: $backup"
	echo "Base Directory:   $basedir"
	recursiveState
	interactiveState
}
recursiveState()
{
	if $recurse; then
		echo "Recursing subdirectories"
	else
		echo "Not recursing subdirectories"
	fi
}
interactiveState()
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
sort=true
isize=0
process=true
iconize=true
makebackup=true


#
#
#   command line option parseing
#
while [ "$1" != "" ]; do
    case $1 in
		-d )					shift
								basedir=$1
								;;
		-b )					shift
								backup=$1
								;;
		-B | --nobackup )       makebackup=false;;
		-s | --sortonly )		process=false; iconize=false;;
		-N | --nonrecursive )	recurse=false;;
		-v | --verbose )		verbose=true;;
		-q | --quiet )			quiet=true;;
        -i | --interactive )    interactive=true;;
		-n | --numbers )        pound=false;;
		-S | --nosort )			sort=false;;
		-P | --noprocess )      process=false;;
        -h | --help )           usage
                                exit
                                ;;
		-l | --level )			shift
								depth=$1
								;;
		-li )					shift
								isize=$(expr "$1" \* 1024)
								isize=$(expr "$isize" \* 1024)
								interactive=true
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

if [ -z "$item" ]; then
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

if $makebackup; then
	if [ ! -d "$backup" ]; then
		if $verbose; then echo "Attempting to create backup directory: $backup"; fi
		result=$(mkdir -p "$backup" 2>&1)
		if [ ! -d "$backup" ]; then
			if $verbose; then echo "$result"; fi
			echo "Couldn't create backup directory. Script stopping to prevent dataloss"
			exit 1
		fi
	fi
fi

if [ -d "$item" ]; then
	if $verbose; then folderState; fi
	echo "Processing: \"$item\" as a directory"
	processDir "$item"
elif [ -s "$item" ]; then
	recurse=false
 	if $verbose; then folderState; fi
	curdir="$(pwd)"
	if $makebackup; then $(cp "$item" "${backup}"); fi
	cd "$(dirname "$item")"
	
	#process file
	if $process; then 
		processFile "$(basename "$item")"
	else
		if $sort; then #processing includes sorting so only run this if the file wasn't processed
			sortFile "$(basename "$item")"
		fi
	fi
else
	echo "Could not process \"$item\" make sure the name is entered correctly."
fi

if $quiet; then	exec 1>&-; fi