#!/bin/bash
dostuff()
{
	cd "$1"
	toremove="" #just to be safe
	for file in *; do
		rem=""
		if [[ "$file" = "*" ]]; then #empty dir
			toremove=$(pwd)
		else
			if [[ -d "$file" ]]; then
				dostuff "$file"
			else
				if [[ ! -s "$file" ]]; then
					read -p "Empty file in $(pwd) keep? y/[n]: " rem
					case "$rem" in
						y | Y | yes | YES | Yes ) :;;
						* )	$(rm "$file")
					esac
				fi
			fi
		fi
	done
	cd ".."
	if [[ -n "$toremove" ]]; then
		read -p "Remove folder \"$toremove\"? y/[n]: " rem
		case "$rem" in
			y | Y | yes | YES | Yes ) $(rm -r "$toremove");;
		esac		
	fi
}
base=$(pwd)
dostuff "$1"