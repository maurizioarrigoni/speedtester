#!/bin/bash
#
# author: Maurizio Arrigoni
# creation date: 5 Jan 2018 
#
# convert speedtest-cli output to a CSV
#

# speedtest-cli --no-pre-allocate

if [ $# -lt 1 ]; then
  echo "Usage: $0 -cycles=n -delay=s (second between two cycles)"
  exit 99
fi

for i in "$@"
do
  case $i in
    -cycles=*)
    CYCLES="${i#*=}"
    shift # past argument=value
    ;;
    -delay=*)
    DELAY="${i#*=}"
    shift # past argument=value
    ;;
  esac
done

[[ ${CYCLES} = "" ]] && CYCLES=48	# 48 cycles * 30 minutes = 1 day
[[ ${DELAY} = "" ]] && DELAY=1800 	# 30 minutes

#echo "CYCLES = ${CYCLES}"
#echo "DELAY = ${DELAY}"

trap echo 0

# headers
echo "hosted_by;ping_latency;download_bandwidth;upload_bandwidth"

hosted_by=""
ping_latency=""
download_bandwidth=""
upload_bandwidth=""

cmd="speedtest-cli --no-pre-allocate"

i=0
while [ $i -lt ${CYCLES} ]; do

	timestamp=$(date +"%d/%m/%Y;%H:%M:%S")
	echo -n $timestamp

	#cat "output.txt" | while read line; do
	$cmd | while read line; do

		if [[ "$line" =~ "Retrieving" ]] || [[ "$line" =~ "Selecting best" ]] || [[ "$line" =~ "Testing download" ]] || [[ "$line" =~ "Testing upload" ]] ; then
	                # skip line
	                continue
	        fi

		if [[ "$line" =~ "Hosted by " ]]; then
			hosted_by=${line#Hosted by }				# remove 'Hosted by ' from string
			hosted_by=${hosted_by%:*}
			ping_latency=${line#*: }
			ping_latency=${ping_latency% ms}                     	# remove ' ms' from string
	                ping_latency=${ping_latency/./,}			# substitute '.' with ','
			echo -n \;\"$hosted_by\"\;$ping_latency
			continue
		fi

	        if [[ "$line" =~ "Download:" ]]; then
			download_bandwidth=${line#Download: }			# remove 'Download: ' from string
			download_bandwidth=${download_bandwidth% Mbit/s}	# remove 'Mbit/s' from string
			download_bandwidth=${download_bandwidth/./,}		# substitute '.' with ','
			echo -n \;$download_bandwidth
	                continue
	        fi

	        if [[ "$line" =~ "Upload:" ]]; then
			upload_bandwidth=${line#Upload: }                   	# remove 'Upload: ' from string
			upload_bandwidth=${upload_bandwidth% Mbit/s}       	# remove 'Mbit/s' from string
			upload_bandwidth=${upload_bandwidth/./,}            	# substitute '.' with ','
			echo \;$upload_bandwidth
	                continue
        	fi

	done

        i=$((i+1))

done

