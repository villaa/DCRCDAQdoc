#!/bin/sh

DEL1=$1
DEL2=$2
DEL3=$3
FILE=$4
BASEFILE=`echo ${FILE}|awk 'BEGIN{FS="."}{print $1}'`

for i in -3 -2 -1 0 1 2 3
do
   awk -v del1=${DEL1} -v del2=${DEL2} -v del3=${DEL3} -v mult=${i} -f DAQDAQ2.awk ${FILE} > ${BASEFILE}_mult_${i}.xml
done
