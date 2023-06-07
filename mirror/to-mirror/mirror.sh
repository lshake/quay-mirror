#!/usr/bin/env bash

# set -x

SOURCE=${SOURCE:='source.example.com'}
DEST=${DEST:='dest.example.com'}
DEST_PROTOCOL=${DEST_PROTOCOL:='docker'}
OAUTH=${OAUTH:='myquayaouthtoken'}
NAMESPACE=${NAMESPACE:='mynamespace'}

RETRIES=${RETRIES:='3'}
ATTEMPTS=${ATTEMPTS:=3}
EXTRA_ARGS=${EXTRA_ARGS:=''}
AUTHFILE=${AUTHFILE:='./auth.json'}

check_bash_version () {
	if [ "${BASH_VERSINFO:-0}" -lt 4 ]
	then
		echo "Needs bash version 4 an above"
		exit 1
	fi
}

get_repositories () {
	repositories=()
	newrepos=()
	local nextpage=''
	local morepages=true
	while [ "$morepages" = true ]
	do
		request=$(curl -s -X GET -H "Authorization: Bearer $OAUTH" "https://$SOURCE/api/v1/repository?namespace=$NAMESPACE&next_page=$nextpage")
		readarray -t newrepos < <(echo $request | jq -r '.repositories[] | .name')
		repositories+=(${newrepos[@]})
		nextpage=$(echo $request | jq -r '.next_page')
		if [[ $nextpage == 'null' ]]
		then
			morepages=false
		fi
	done
	readarray -t repositories < <(printf '%s\n' "${repositories[@]}" | sort | uniq)
}

get_tags () {
	tags=()
	local newtags=()
	local page=1
	local morepages=true
	local tagfilter=""

	if [ ! -z $TAG_FILTER ]
	then
		tagfilter="&filter_tag_name=${TAG_FILTER}"
	fi

	while [ "$morepages" = true ]
	do
		request=$(curl -s -X GET -H "Authorization: Bearer $OAUTH" "https://$SOURCE/api/v1/repository/$NAMESPACE/$r/tag/?page=$page&limit=100$tagfilter")
		readarray -t newtags < <(echo $request | jq -r '.tags[] | .name')
		if (( ${#newtags[@]} > 0 ))
		then
			tags+=(${newtags[@]})
		fi
		((page++))
		morepages=$(echo $request | jq -r '.has_additional')
	done
	readarray -t tags < <(printf '%s\n' "${tags[@]}" | sort | uniq)
}

main () {
	check_bash_version
	get_repositories
	for r in "${repositories[@]}"
	do
		get_tags
		if [ ! -z "$tags" ]
		then
			echo "Repository : $NAMESPACE / $r"
			retval=99
			for ((pass=1;pass<=${ATTEMPTS};pass++))
			do
				skopeo sync $EXTRA_ARGS --authfile $AUTHFILE --retry-times $RETRIES --all --src docker --dest $DEST_PROTOCOL $SOURCE/$NAMESPACE/$r $DEST/$NAMESPACE/$r
				retval=$?
				if  [[ $retval -eq 0 ]]
				then
					break
				fi
				echo "Retrying : $pass"
			done
			if  [[ $retval -ne 0 ]]
			then
				echo "Failed : $retval"
				exit 1
			fi
		fi
	done
}

main
echo "Completed mirror"
exit 0
