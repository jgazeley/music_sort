# Working directory
directory="/mnt/d/desktop/filter"

# Music Library directory
music="/mnt/e"

# Changes certain words to lowercase in song titles
function capitals {
	for argument; do
		case $1 in
			In) title=$(echo $title | sed 's/\ In\ /\ in\ /')
			;;
			Is) title=$(echo $title | sed 's/\ Is\ /\ is\ /')
			;;
			The) title=$(echo $title | sed 's/\ The\ /\ the\ /')
			;;
			With) title=$(echo $title | sed 's/\ With\ /\ with\ /')
			;;
			A) title=$(echo $title | sed 's/\ A\ /\ a\ /')
			;;
			As) title=$(echo $title | sed 's/\ As\ /\ as\ /')
			;;
			And) title=$(echo $title | sed 's/\ And\ /\ and\ /')
			;;
			For) title=$(echo $title | sed 's/\ For\ /\ for\ /')
			;;
			From) title=$(echo $title | sed 's/\ From\ /\ from\ /')
			;;
			To) title=$(echo $title | sed 's/\ To\ /\ to\ /')
			;;
			Or) title=$(echo $title | sed 's/\ Or\ /\ or\ /')
			;;
			Of) title=$(echo $title | sed 's/\ Of\ /\ of\ /')
			;;
			On) title=$(echo $title | sed 's/\ On\ /\ on\ /')
			;;
		esac
	shift
	done
	echo $title
}

# Creates variables with metadata for ARTIST, ALBUM, YEAR, TITLE, and TRACKNUMBER
function meta {
	input="$directory/$1"
	metaflac --export-tags-to=/mnt/d/desktop/tags.txt "$input"

	artist=$(grep ^ARTIST= /mnt/d/desktop/tags.txt | cut -f2-20 -d=)

		# Artists with "The" in the name are reformatted to "Bandname, The"
		if [[ "$artist" =~ ^"The " ]]; then
			artist=$(echo $artist | sed 's/The\ //' | sed 's/$/,\ The/')
		fi

	track=$(grep ^TRACKNUMBER= /mnt/d/desktop/tags.txt | cut -f2-20 -d=)

		if [[ $track =~ ^0[123456789]* ]]; then
			metaflac --remove-tag=TRACKNUMBER "$input"
			metaflac --set-tag="TRACKNUMBER=${track:1}" "$input" 
		fi

		# Track numbers 1-9 are formatted as 01-09 in file names
		if [[ $track =~ ^[1-9]$ ]]; then
			track=0$track 
		fi

	# Song titles are formatted using "capitals" function (see above)
	title=$(grep ^TITLE= /mnt/d/desktop/tags.txt | cut -f2-20 -d=)
		title=$(capitals $title)
		metaflac --remove-tag=TITLE "$input"
		metaflac --set-tag="TITLE=$title" "$input"

	album=$(grep ^ALBUM= /mnt/d/desktop/tags.txt | cut -f2-20 -d=)
	year=$(grep ^DATE= /mnt/d/desktop/tags.txt | cut -f2-20 -d=)
	format=$(exiftool "$input" | grep "File Type Extension" | cut -f2 -d: | cut -f2 -d\ )
	
	# File names are formatted as TRACKNUMBER. TITLE.flac
	filename=$(echo $track\. $title\.$format)
}

# Create list.txt with files from working directory
ls -1 $directory > /mnt/d/desktop/list.txt

# Options
for argument; do
	case $1 in

		# \-setup)
		# ;;

		# Display files in working directory:
		# filenames and ARTIST -  ALBUM - YEAR
		test)
			while read list; do
				meta "$list"
				echo $filename
			done < /mnt/d/desktop/list.txt
			echo $artist - $album - $year
		;;

		# Change ALBUM for entire working directory to argument
		# ex: sort.sh -album "Sgt. Pepper's Lonely Hearts Club Band"
		\-album)
			val=$2
			while read list; do
				metaflac --remove-tag=ALBUM "$list"
				metaflac --set-tag="ALBUM=$val" "$list"
			done < /mnt/d/desktop/list.txt
		;;

		# Change ARTIST for entire working directory to argument
		# ex: sort.sh -artist "The Beatles"
		\-artist)
			val=$2
			while read list; do
				metaflac --remove-tag=ARTIST "$list"
				metaflac --set-tag="ARTIST=$val" "$list"
			done < /mnt/d/desktop/list.txt
		;;

		# Run the main script; renames files in working directory
		# and sorts the files into the music directory
		run)
			cd /mnt/e
			while read list; do
				meta "$list"

			if ! [ -e "$music/$artist" ]; then
				mkdir "$music/$artist"
			fi

			if ! [ -e "$music/$artist/$album" ]; then
				mkdir "$music/$artist/$album"
			fi

			mv "$input" "$music/$artist/$album/$track. $title.$format"
			done < /mnt/d/desktop/list.txt
		;;
	esac
done

# Remove intermediate files
rm /mnt/d/desktop/list.txt /mnt/d/desktop/tags.txt