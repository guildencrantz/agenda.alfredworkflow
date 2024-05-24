DATE=$1
TEXT=$2
LIST=$3

DATE_ARG="--due-date \"$DATE\""

if [ -z "$DATE" ]; then
	DATE_ARG=""
fi

echo "./agenda add-reminder \"$LIST\" \"$TEXT\" $DATE_ARG" >/dev/stderr

eval "./agenda add-reminder \"$LIST\" \"$TEXT\" $DATE_ARG"

