#!/bin/sh

CHART=$1
shift

OUTPUT_FILE=$CHART/_image-set.json

CONTENT=$(cat $OUTPUT_FILE)
while [ $# != 0 ]; do
  CONTENT=$(echo $CONTENT | jq ".images+=[{\"image\": \"$1\"}]")
  shift
done
cat > $OUTPUT_FILE << EOF
$CONTENT
EOF
