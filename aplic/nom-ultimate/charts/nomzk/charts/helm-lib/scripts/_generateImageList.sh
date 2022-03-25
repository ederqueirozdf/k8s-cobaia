#!/bin/sh

CHART=$1
shift; ARGS="$@"

if [ -z "$CHART" ] ; then
    echo "ERROR: Must specify chart directory"
    exit 1
fi

if [ ! -d $CHART -o ! -f $CHART/Chart.yaml ] ; then
    echo "ERROR: Specified parameter does not appear to be a Helm chart"
    exit 1
fi

REGISTRY="docker.io/"
ORGNAME="${ORGNAME:-hpeswitom}"
DESC=`grep -Po '^description:.*' $CHART/Chart.yaml | cut -f2- -d: | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//'`

OUTPUT_FILE=$CHART/_image-set.json
rm -f $OUTPUT_FILE


# Used to determine whether to insert "," into the list of images.  We DON'T do it for the first entry in the list,
# because the code is inserting the comma at the top of the loop, after having printed the "image:" line at the
# end of the loop.
FIRSTENTRY=true


TMPFILE=/tmp/template.$$
helm template $CHART $ARGS > $TMPFILE
RC=$?
if [ $RC -ne 0 ] ; then
    echo "ERROR: Helm template returned non-zero status: $RC"
    exit 1
fi

printf '{\n  "suite": "%s",\n  "display_name": "%s",\n  "org_name": "%s",\n  "version": "%s",\n  "images": [' "${PROJECT}" "${DESC}" "$ORGNAME" "${VERSION}" >> $OUTPUT_FILE

cat -v $TMPFILE | grep "image:" | sed -e 's%\^M%%g' | grep -v '^[ ]*#' | awk '{print $NF}' | sed -e 's%"%%g' -e "s%$REGISTRY%%g" -e "s%^$ORGNAME/%%g" | sort -u | while read IMAGE ; do
    if $FIRSTENTRY ; then
        FIRSTENTRY=false
    else
        printf ',' >> $OUTPUT_FILE    # as long as we are in this loop, then we must put "," on previous "image:" line
    fi

    printf '\n    { "image": "%s" }' $IMAGE >> $OUTPUT_FILE   # do NOT do comma (or newline) here, since above will do that
done
rm -f $TMPFILE

printf '\n  ]\n}\n' >> $OUTPUT_FILE

