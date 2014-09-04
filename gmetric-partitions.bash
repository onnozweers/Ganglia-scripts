#!/bin/bash

# Collect partition info (per partition!) and feed it into Ganglia with gmetric.
# The normal disk_free and disk_total can't handle partitions of 20T and more.
# Run this script regularly from a cron job.

PARTITION_INFO=`df --block-size=1 --exclude-type=tmpfs --exclude-type=nfs \
                | grep -v 'Filesystem' \
                | sed -e "/^[^ ]\+$/ { N ; s/\n\s\+/ / } "`
# The final sed rejoins split lines.

echo "$PARTITION_INFO" | while read LINE ; do
  MOUNTPOINT=`echo $LINE | awk '{print $6}'`
  if [ "$MOUNTPOINT" = "/" ] ; then
    PARTITION_NAME='root'
  else
    PARTITION_NAME=`echo $MOUNTPOINT | sed -e 's#/##g'`
  fi
  SIZE=`echo $LINE | awk '{print $2}'`
  USED=`echo $LINE | awk '{print $3}'`
  if [ $SIZE -gt 0 ] ; then
    USED_PERCENTAGE=`echo "scale=2; 100 * $USED / $SIZE" | bc`
  else
    USED_PERCENTAGE=0
  fi
  gmetric --name=partition_${PARTITION_NAME}_size --value=${SIZE} --units=bytes --type=double --dmax=3600
  gmetric --name=partition_${PARTITION_NAME}_used --value=${USED} --units=bytes --type=double --dmax=3600
  gmetric --name=partition_${PARTITION_NAME}_percentused --value=${USED_PERCENTAGE} --units="%" --type=float --dmax=3600
done
