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

# Creates variables with metadata for ARTIST, ALBUM, DATE, GENRE, TITLE, and TRACKNUMBER
function meta {
	input="$directory/$1"
	metaflac --export-tags-to=/mnt/d/desktop/tmp/tags.txt "$input"

	artist=$(grep -i ^ARTIST= /mnt/d/desktop/tmp/tags.txt | cut -f2-20 -d=)

	track=$(grep -i ^TRACKNUMBER= /mnt/d/desktop/tmp/tags.txt | cut -f2-20 -d=)

		if [[ $track =~ ^0[123456789]* ]]; then
			track=${track:1} 
		fi

	title=$(grep -i ^TITLE= /mnt/d/desktop/tmp/tags.txt | cut -f2-20 -d=)
		title=$(capitals $title)

	album=$(grep -i ^ALBUM= /mnt/d/desktop/tmp/tags.txt | cut -f2-20 -d=)
	year=$(grep -i ^DATE= /mnt/d/desktop/tmp/tags.txt | cut -f2-20 -d=)
	genre=$(grep -i ^GENRE= /mnt/d/desktop/tmp/tags.txt | cut -f2-20 -d=)
	format=$(exiftool "$input" | grep "File Type Extension" | cut -f2 -d: | cut -f2 -d\ )
	
	metaflac --remove-all-tags "$input"
	metaflac --set-tag="ARTIST=$artist" "$input"
	metaflac --set-tag="ALBUM=$album" "$input"
	metaflac --set-tag="GENRE=$genre" "$input"
	metaflac --set-tag="DATE=$year" "$input"
	metaflac --set-tag="TITLE=$title" "$input"
	metaflac --set-tag="TRACKNUMBER=$track" "$input"

	# Artists with "The" in the name are reformatted to "Bandname, The"
	if [[ "$artist" =~ ^"The " ]]; then
		artist=$(echo $artist | sed 's/The\ //' | sed 's/$/,\ The/')
	fi

	# Track numbers 1-9 are formatted as 01-09 in file names
	if [[ $track =~ ^[1-9]$ ]]; then
		track=0$track 
	fi

	# Replace special characters with '-' in file names
	title=$(echo $title | sed 's/\?/\-/')
	title=$(echo $title | sed 's/\:/\-/')

	# File names are formatted as 'nn. title.flac'
	filename=$(echo $track\. $title\.$format)

}

# Create list.txt with files from working directory
ls -1 $directory > /mnt/d/desktop/tmp/list.txt

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
			done < /mnt/d/desktop/tmp/list.txt
			echo $artist - $album - $year
		;;

		meta)
			while read list; do
				meta "$list"
				echo $filename
				metaflac --export-tags-to=/mnt/d/desktop/tmp/tags.txt "$directory/$list"
				cat /mnt/d/desktop/tmp/tags.txt
				echo
			done < /mnt/d/desktop/tmp/list.txt
		;;

		# Change ALBUM for entire working directory to argument
		# ex: sort.sh -album "Pet Sounds"
		\-album)
			val=$2
			while read list; do
				metaflac --remove-tag=ALBUM "$directory/$list"
				metaflac --set-tag="ALBUM=$val" "$directory/$list"
			done < /mnt/d/desktop/tmp/list.txt
		;;

		# Change ARTIST for entire working directory to argument
		# ex: sort.sh -artist "Thelonious Monk"
		\-artist)
			val=$2
			while read list; do
				metaflac --remove-tag=ARTIST "$directory/$list"
				metaflac --set-tag="ARTIST=$val" "$directory/$list"
			done < /mnt/d/desktop/tmp/list.txt
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
			done < /mnt/d/desktop/tmp/list.txt
		;;
	esac
done

# Remove intermediate files
rm /mnt/d/desktop/tmp/*txt