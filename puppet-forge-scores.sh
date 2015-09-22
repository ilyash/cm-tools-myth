#!/bin/bash -eu

BASE_URL='https://forgeapi.puppetlabs.com'
START_PATH='/v3/modules?puppet_requirement=%3E%3D3.0.0&sort_by=latest_release&limit=100'

T=$(mktemp -d)
echo "* Using temp dir $T"

cleanup() {
	echo "* Cleaning up temp dir $T"
	rm -r "$T"
}

trap cleanup EXIT

path=$START_PATH

while true;do
	u="$BASE_URL$path"
	echo "* Fetching $u"
	content=$(curl -s "$u")
	echo "$content" | jq '.results[].feedback_score' >>"$T/scores"
	path=$(echo "$content" | jq -r '.pagination.next')
	# echo "[DEBUG] $path"
	if [[ $path == null ]];then
		break
	fi
done

echo "[feedback scores]"
grep -v null "$T/scores" | sort | sed 's/^\(.\)\(.\)$/\1X/; s/^\(.\)$/0X/' | sort | uniq -c | sort -k2 -n
echo "[number of modules with feedback scores]"
grep -c -v null "$T/scores"
echo "[number of modules without feedback scores]"
grep -c null "$T/scores"
echo "[total number of modules]"
grep -c . "$T/scores"
