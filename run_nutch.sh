#!/bin/bash

# short script to help crawl

unset SEGMENT

# set this to your nutch home dir
NUTCH_HOME="/usr/share/nutch"

cd ${NUTCH_HOME}

${NUTCH_HOME}/bin/nutch generate crawl/crawldb crawl/segments
[ $? = 0 ] || { echo "An error occured while generating the fetch list!"; exit $?; }

export SEGMENT=crawl/segments/`ls -tr crawl/segments|tail -1`
${NUTCH_HOME}/bin/nutch fetch $SEGMENT -noParsing
[ $? = 0 ] || { echo "An error occured while FETCHING the content!"; exit $?; }

${NUTCH_HOME}/bin/nutch parse $SEGMENT
[ $? = 0 ] || { echo "An error occured while PARSING the content!"; exit $?; }

${NUTCH_HOME}/bin/nutch updatedb crawl/crawldb $SEGMENT -filter -normalize
[ $? = 0 ] || { echo "An error occured while updating the crawl DB!"; exit $?; }

${NUTCH_HOME}/bin/nutch invertlinks crawl/linkdb -dir crawl/segments
[ $? = 0 ] || { echo "An error occured while creating link database!"; exit $?; }

# success!
exit 0

#EOF