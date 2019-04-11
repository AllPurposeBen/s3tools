#!/bin/bash

### Tool for getting the size of various S3 buckets I have access to
# requires awscli to be configured for a specific set of credentials as default or previously exported in session
# TODO: add monetary accounting to see what we spend.
# TODO: make output pretty

## function for byte conversion, cribbed from https://gist.github.com/gnif/cadc611f04998706559def45318a0129
function bytesToHR()
{
  local SIZE=$1
  local UNITS="B KiB MiB GiB TiB PiB"
  for F in $UNITS; do
    local UNIT=$F
    test ${SIZE%.*} -lt 1024 && break;
    SIZE=$(echo "$SIZE / 1024" | bc -l)
  done

  if [ "$UNIT" == "B" ]; then
    printf "%4.0f    %s\n" $SIZE $UNIT
  else
    printf "%7.02f %s\n" $SIZE $UNIT
  fi
}

## get list of bucket names
bucketList=$(aws s3 ls | awk '{print $NF}')
echo "Querying S3 for data, this may take some time..."

## Loop though each and get a size
bigTotal=0
for thisBucket in $(echo $bucketList); do
	thisTotalBytes=$(aws s3 ls s3://$thisBucket --recursive --summarize | grep 'Total Size' | awk -F ': ' '{print $NF}')
	if [[ -z $thisTotalBytes ]]; then
		echo "ERROR: Couldn't get size for bucket $thisBucket."
		continue
	fi
	thisTotalHR=$(bytesToHR $thisTotalBytes)
	# add the to the big total
	bigTotal=$((bigTotal+$thisTotalBytes))
	# talk about it
	echo "$thisBucket: $(bytesToHR $thisTotalBytes)"
done

## Print the big total
echo ''
echo "Total Space: $(bytesToHR $bigTotal)"

exit 0