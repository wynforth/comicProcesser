
os=$(uname)

usage() {
	echo "Applies a custom icon to a folder based on the naming scheme of the folder, depth of the folder doesn't matter. If there is no matching icon it will list out the folder so you know what you need to create icons for.
For examples
given:
	basedir = ~/Comics/
	Iconlocation = ~/Icons/

for a given folder ie ~/Comics/Spider-Man/The Amazing Spider-Man/
it will try to use the icon ~/Icons/Spider-Man - The Amazing Spider-Man.icns (or .ico for linux)
	
$0 [opts] dir icons
	
	directory     The base directory to use, all folders in this directory will be used, it will not add an icon to this directory
	icons		  Directory where your icons are kept. it will try the base directory, if an icon is not found it will then try a subdirectory of either icns/ or ico/
	
OPTIONS:
	-R, --nonrecursive     Will not recurse subdirectories
	-bg					   Set a folder background image if found (only works on OSX)
	-v, --verbose          Displays extra output" 
	
}

processDir()
{
	
	dir="$1"
	cd "$dir"
	#if [[ -n "$2" ]]; then iconname="$2 - "; fi
	if [[ -z "$baselen" ]]; then
		tmp="$(pwd)/"
		baselen=${#tmp}
	fi
	for item in *; do
		if [[ -d "$item" ]]; then
			cur="$(pwd)/$item"
			cur="${cur:$baselen}"
			cur="${cur//\// - }"
			#if $verbose; then echo "Processing: $item"; fi
			if [[ "$os" = "Darwin" ]]; then
				iconname="${cur}.icns"
			else
				iconname="${cur}.ico"
			fi
			
			#echo "$icondir/$iconname"
			if [[ -s "$icondir/$iconname" ]]; then
				ficon="$icondir/$iconname"
			elif [[ -s "$icondir/icns/$iconname" ]]; then
				ficon="$icondir/icns/$iconname"
			elif [[ -s "$icondir/ico/$iconname" ]]; then
				ficon="$icondir/ico/$iconname"
			else
				ficon=""
			fi
			
			if [[ -n "$ficon" ]]; then
				echo "Setting icon for: $item"
				if $verbose; then echo "Setting icon for \"$item\" to \"$ficon\""; fi
				if [[ "$os" = "Darwin" ]]; then
					$(seticon -d "$ficon" "$item")
				else
					echo "Icon found but i don't know how to set it on this system yet"
				fi
			else
				echo "Couldn't find icon for \"$cur\""
			fi
			
			#if under OSX also set folder backgrounds...yeah i'm a bit crazy
			#runs an applescript to set the folderBG
			#need to build a toggle for this
			if $setbg; then
				if [[ "$os" = "Darwin" ]]; then
					echo "Setting folder background for: $item"
					fullitem="$(pwd)/$item"
				
					background="$icondir/bg/$cur.jpg"
					if [[ -s "$background" ]]; then

						eval "osascript \"$scriptDir/setFolderBackground.scpt\" \"$fullitem\" \"$background\" >> /dev/null"
					else
						#if jpg doesn't work try png
						background="$icondir/bg/$cur.png"
						if [[ -s "$background" ]]; then
							eval "osascript \"$scriptDir/setFolderBackground.scpt\" \"$fullitem\" \"$background\" >> /dev/null"
						fi
					fi	
				fi
			fi
			
			if $recurse; then
				processDir "$item"
			fi
			
			
		fi
	done

	cd ".."
		
	
}

###############
# Defaults

recurse=true;
verbose=false;
setbg=false

while [ "$1" != "" ]; do
    case $1 in
        -R | --nonrecursive )		recurse=false;;
		-v | --verbose )    		verbose=true;;
		-bg )						setbg=true;;
        * )							if [[ -z "$3" ]]; then
										basedir="$1"
										shift
										icondir="$1"
									else
										usage
		                               	exit 1
									fi
    esac
    shift
done

if [[ -z "$basedir" ]] | [[ -z "$icondir" ]]; then
	usage
	exit 1
fi

basedir=$(cd "$basedir"; pwd)
icondir=$(cd "$icondir"; pwd)

if [[ ! -d "$basedir" ]]; then
	echo "$basedir could not be found"
	exit 1
fi

if [[ ! -d "$icondir" ]]; then
	echo "$icondir could not be found"
	exit 1
fi

if [[ "$basedir" = */ ]]; then basedir=${basedir%/}; fi
if [[ "$icondir" = */ ]]; then icondir=${icondir%/}; fi
scriptDir=$(pwd)
seticon=$(which seticon)
if [ -z "$seticon" ]; then
	echo "Could not locate seticon in $PATH. It is part of OSX Utils and found at http://www.sveinbjorn.org/osxutils_docs"
	echo "The script will continue however icons may not be properly created."
	seticon="/usr/local/bin/seticon"
fi

#echo "$baselen"

processDir "$basedir"
